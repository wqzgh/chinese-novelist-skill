#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Regression tests for chapter word-count extraction."""

import tempfile
import unittest
from pathlib import Path

from check_chapter_wordcount import check_chapter, extract_content_from_chapter


SAMPLE = """# 第01章：测试

## 本章概要
- **核心事件**：这段概要有很多汉字用来灌水灌水灌水灌水灌水灌水灌水灌水灌水灌水

## 章首引子

> 门开了。

## 正文

她把刀放下。灯光很白。他问你还活着吗。她说先看标本。

## 章节备注
- 本章悬念：灌水灌水灌水灌水灌水灌水灌水灌水灌水灌水
"""


class WordCountTests(unittest.TestCase):
    def test_excludes_summary_and_notes(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / '第01章-测试.md'
            path.write_text(SAMPLE, encoding='utf-8')
            extracted = extract_content_from_chapter(path)
            self.assertNotIn('核心事件', extracted)
            self.assertNotIn('本章悬念', extracted)
            self.assertIn('先看标本', extracted)
            self.assertIn('门开了', extracted)
            result = check_chapter(str(path), min_words=1)
            # 概要/备注中的「灌水」不得计入
            self.assertLess(result['word_count'], 40)
            self.assertGreater(result['word_count'], 10)


if __name__ == '__main__':
    unittest.main()
