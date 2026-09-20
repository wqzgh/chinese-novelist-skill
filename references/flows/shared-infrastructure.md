# 共享机制

本文件定义跨阶段共享的机制和规则。

---

## 三大黄金法则

1. **展示而非讲述** - 用动作和对话表现，不要直接陈述
2. **冲突驱动剧情** - 每章必须有冲突或转折
3. **悬念承上启下** - 每章结尾必须留下钩子

---

## 用户偏好系统

### 存储文件

`user-preferences.json`（项目根目录，首次使用后自动创建）

### 数据结构

```json
{
  "version": 1,
  "updatedAt": "2026-04-12",
  "preferences": {
    "favoriteGenres": [],
    "preferredProtagonist": "",
    "preferredPerspective": "",
    "preferredTone": "",
    "typicalChapterCount": null,
    "styleReferences": [],
    "dislikes": [],
    "creationHistory": []
  }
}
```

### 偏好更新规则

| 时机 | 行为 |
|------|------|
| 每完成一层问答 | 静默将本层回答同步到偏好文件（追加/更新，不删除历史） |
| 用户说"记住我的偏好" | 保存当前所有配置到偏好 |
| 用户说"忘记XX偏好" | 清除指定维度的偏好 |
| 用户说"重置偏好" | 清空所有偏好数据 |
| 一部长篇创作完成 | 将作品信息追加到 `creationHistory` |

### 偏好如何影响交互

1. **启动欢迎语**：有偏好时显示"欢迎回来！" + 个性化提示
2. **选项排序**：Q1中将 `favoriteGenres` 匹配项排前面
3. **常用标记**：Q5/Q8中对应用⭐标记"你的常用"/"上次选择"
4. **需求报告**：结合偏好给个性化建议（如"你之前喜欢悬疑+第三人称限制，这次要不要试试多视角？"）
5. **随机生成**：优先从偏好范围内随机选取，保持一致性
6. **风格参考追问**：优先推荐 `styleReferences` 中的作者

### 错误恢复

- **回退修改**：用户随时可说"回到QX"、"修改XX"，AI 回退到指定问题重新询问
- **中途暂存**：通过 `02-写作计划.json` 实现自动暂存；下次触发SKILL时 Phase 0 自动检测未完成项目，询问"继续上次的《XXX》？"
- **偏好文件损坏**：JSON解析失败时忽略偏好，使用默认值，并在后台修复文件

---

## 标题传递机制

### 传递方式

标题通过**对话上下文**在阶段间传递，不单独持久化到文件。

**传递链路**：
1. Phase 1 Layer 3：用户选择/确认标题 → 标题存入对话上下文
2. Phase 2：从上下文读取标题 → 写入项目目录名、`02-写作计划.json`、`01-大纲.md`

### 中断恢复

若会话在 Layer 3 完成、Phase 2 开始前中断：
- Phase 0 不会找到已创建的项目目录（因为 Phase 2 尚未执行）
- 用户将重新进入 Layer 3 重新选择标题（标题选择耗时很短，重新选择成本可接受）

## 写作计划系统

### 存储文件

`02-写作计划.json`（项目文件夹内，Phase 2 创建）

### 作用

- **进度跟踪**：记录每章创作状态（pending / in_progress / awaiting_review / completed / failed）
- **写作模式**：记录用户选择的写作模式（serial-review / serial / subagent-parallel / agent-teams）
- **中断续写**：Phase 0 读取 JSON 检测未完成项目，支持从断点继续
- **校验依据**：Phase 4 基于 JSON 校验章节完成度和字数
- **并行协调**（可选）：多 Agent 并行写作时通过 JSON 状态避免冲突

`awaiting_review`：本章正文已写完、字数已检查，正在等人审核。`serial-review` 模式下，存在任一 `awaiting_review` 时禁止开始下一章。用户说「通过 / 下一章」后改为 `completed`。用户要求改稿则保持该章并重写，再回到 `awaiting_review`。

### 与大纲的关系

- `01-大纲.md`：章节规划（核心事件、悬念钩子、承接上章、出场人物、场景列表）+ 章节摘要（连贯性参考）+ 设定词典（设定名词的首现与揭示跟踪）
- `02-写作计划.json`：章节状态、字数、重试次数、写作模式（机器可读的进度跟踪）
- Phase 3 创作每章时必须读取 `01-大纲.md` 中对应章节的规划信息，作为创作依据
- 两者严格对应：JSON 中的 `chapterNumber` 和 `title` 必须与大纲中的章节规划一致

### JSON 损坏处理

- JSON 解析失败时：提示用户，尝试从大纲的章节摘要区推断完成进度
- 章节状态丢失时：通过文件存在性和字数脚本重建状态

---

## 交互运行时适配

本 skill 最初按 Claude Code 的 `AskUserQuestion` 编写。Cursor、Cloud Agent 以及多数 IDE 没有该工具。按下面顺序选择交互方式，不要因为工具缺失而中断流程。

| 优先级 | 条件 | 做法 |
|--------|------|------|
| 1 | 当前环境有结构化提问工具（如 `AskUserQuestion`） | 用它展示选项 |
| 2 | 普通对话、可以等用户回复 | 用同样的选项列表在对话里提问，一次一题；**规划、标题、每一章都要等回复** |
| 3 | **直接开写**：仅当当前环境确定收不到下一句用户回复（纯后台、无后续对话），且用户没有要求确认 | 执行下方「直接开写协议」 |

禁止把「开始写一部小说」理解成可以跳过确认。用户还在对话中时，一律走优先级 2。

用户如果说「都要跟我确认」「写完一章我审核后再继续」：写作模式锁定 `serial-review`，即使后台任务也要在每章结束后停下等下一句。

### 直接开写协议

仅适用于优先级 3。

1. 用已有信息 + 智能随机补全 Q1–Q8（有 `user-preferences.json` 时优先从偏好里取）
2. 按 Layer 3 规则生成 3 个候选标题，选定最贴合的 1 个
3. 把完整创作配置与标题写入项目文件（仍应在能展示时展示）
4. 写作模式默认 `serial-review`；只有用户明确说「一口气写完 / 不用每章确认」才用 `serial`
5. 进入 Phase 2 创建项目文件。`serial-review` 下写完第 1 章必须停止。

---

## 字数检查脚本

脚本在 **skill 根目录**（`SKILL.md` 所在目录）的 `scripts/check_chapter_wordcount.py`。小说写在用户工作区的 `./chinese-novelist/`，两者经常不是同一个目录。必须用脚本的真实路径，禁止假设当前工作目录就是 skill 根目录。

定位 skill 根目录：本仓库 / 已安装目录（例如 `~/.cursor/skills/chinese-novelist/` 或 `~/.claude/skills/chinese-novelist/`）。

```bash
SKILL_ROOT="<本 skill 的根目录>"

# 检查单个章节
python3 "$SKILL_ROOT/scripts/check_chapter_wordcount.py" ./chinese-novelist/项目文件夹/第01章-标题.md

# 检查所有章节
python3 "$SKILL_ROOT/scripts/check_chapter_wordcount.py" --all ./chinese-novelist/项目文件夹/

# 自定义最小字数
python3 "$SKILL_ROOT/scripts/check_chapter_wordcount.py" ./chinese-novelist/项目文件夹/第01章-标题.md 3500
```

### 使用场景

| 阶段 | 用途 |
|------|------|
| Phase 3（逐章创作） | 撰写后检查单章字数，低于3000字必须扩充 |
| Phase 4（自动校验） | 批量检查所有章节字数，不合格章节自动重写 |

低于3000字的章节必须使用 [content-expansion.md](../guides/content-expansion.md) 的扩充技巧进行扩充。

**统计范围**：只计 `## 章首引子` 与 `## 正文` 中的汉字。`本章概要`、`章节备注` 以及 Markdown 标题不计入。旧文件若没有这两个标题，则回退为「跳过第一个含章的标题行后的全部内容」。
