import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: '/DataStructure-with-Zig/',
  title: "Data Structure with Zig",
  description: "Learning Zig by writing data structures.",
  srcExclude: [
    'example.md',
    '**/**.z.md'
  ],
  locales: {
    root: {
      label: '简体中文',
      lang: 'zh-CN'
    },
    en: {
      label: 'English',
      lang: 'en',
      link: '/docs/en'
    }
  },

  // TODO: make a theme config for each language
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'The Book', link: '/docs' },
    ],

    sidebar: [
      {
        text: 'The Book',
        items: [
          { text: '关于DSwZ', link: './00_introduction' },
          { text: 'Zig基础', link: './01_zig_basics' },
          { text: '数组列表ArrayList', link: './02_array_list' },
          { text: '链表LinkedList', link: './03_linked_list' },
          { text: '栈Stack', link: './04_stack' },
          { text: '队列Queue', link: './05_queue' },
          { text: '哈希表Hash Table', link: './06_hash_table' },
          { text: '总结和回顾', link: './07_summary' },
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/IncorrectM/DataStructure-with-Zig' }
    ]
  }
})
