---
name: chinese-novelist
description: |
  Use when the user asks to write a Chinese novel, long-form story, chaptered fiction, 网文, or to continue an unfinished chinese-novelist project. Also use when installing, testing, or dogfooding this skill.
metadata:
  trigger: 创作中文小说、分章节故事、长篇小说创作
  source: 基于小说创作最佳实践设计
---

# Chinese Novelist: 中文小说创作助手

## 三大黄金法则

1. **展示而非讲述** - 用动作和对话表现，不要直接陈述
2. **冲突驱动剧情** - 每章必须有冲突或转折
3. **悬念承上启下** - 每章结尾必须留下钩子

## 特性说明

- **中断续写**：自动检测未完成项目，从断点继续创作
- **逐章审核**（默认，交互式）：每章写完必须停下来等人审过，才能写下一章
- **自动校验**：创作完成后自动检查字数和质量，不合格自动修复
- **并行写作**（可选）：支持子Agent并行写作，通过 `02-写作计划.json` 协调状态

## 核心流程

进入每个阶段时，先阅读对应的流程文档以获取详细执行指令。

**运行时适配（必读）**：本 skill 必须能在 Claude Code、Cursor Agent、Cloud Agent 中同样跑通。提问方式、确认门闩、字数脚本路径见 [shared-infrastructure.md](references/flows/shared-infrastructure.md)「交互运行时适配」与「字数检查脚本」。禁止因为没有 `AskUserQuestion` 而停住；也禁止在用户能回复时擅自跳过确认。

用户如果说「都要跟我确认」「写完一章我审核后再继续」：强制 `writingMode: serial-review`，规划、标题、每一章都必须等人点头。

### 第0步：初始化与偏好加载

读取用户偏好，检测未完成项目（中断续写），展示个性化欢迎。 → 详见 [phase0-initialization.md](references/flows/phase0-initialization.md)

### 第一阶段：三层递进式问答

通过递进式问答收集创作需求，确定小说定位与标题：

- **核心定位**（必答，Q1-Q3）：题材创意、主角设定、核心冲突 → 详见 [phase1-layer1-core.md](references/flows/phase1-layer1-core.md)
- **深度定制与规格**（Q4-Q8）：世界观、视角基调、核心主题、读者定位、章节数量、配置确认 → 详见 [phase1-layer2-customize.md](references/flows/phase1-layer2-customize.md)
- **标题生成**：AI 基于创意元素生成候选标题，用户选择或自定义 → 详见 [phase1-layer3-title.md](references/flows/phase1-layer3-title.md)

### 第二阶段：规划 + 二次确认

创建项目文件夹（`./chinese-novelist/{timestamp}-{小说名称}/`），生成大纲、人物档案和写作计划JSON，等待用户确认。 → 详见 [phase2-planning.md](references/flows/phase2-planning.md)

### 第2.5步：写作模式选择

规划确认后，选择写作模式：
- **逐章审核**（`serial-review`）：写完一章就停，等人审过再写下章。**交互式默认**
- **逐章串行**（`serial`）：主 Agent 自己逐章写，全程无中断（仅当用户明确说「一口气写完 / 不用每章确认」）
- **子Agent并行**（`subagent-parallel`）：将章节分成批次，派生子 Agent 并行写作
- **Agent Teams**（`agent-teams`）：Claude Code 多 Agent 协作模式，Agent 间可通讯（需手动开启）

→ 详见 [phase3-writing.md](references/flows/phase3-writing.md)

### 第三阶段：创作

- `serial-review`：每章写完将状态设为 `awaiting_review`，向用户展示路径与字数，**停止**。未听到「通过 / 下一章」之前禁止动笔下一章。
- `serial` / 并行 / Teams：用户已明确授权一口气写完时，才可连续创作到全稿。

根据用户选择的写作模式逐章执行创作流程。每章创作前必须读取 `01-大纲.md` 中对应章节的规划信息，严格按大纲创作。支持中断续写。 → 详见 [phase3-writing.md](references/flows/phase3-writing.md)

### 第四阶段：自动校验与修复（无需用户确认）

全程无需用户介入，自动检查所有章节完成度和字数，不合格章节自动重写（最多3轮）。 → 详见 [phase4-validation.md](references/flows/phase4-validation.md)

## 共享机制

偏好系统、写作计划系统、黄金法则详解、字数检查脚本等跨阶段共享机制。 → 详见 [shared-infrastructure.md](references/flows/shared-infrastructure.md)
