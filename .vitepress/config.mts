import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: '/DataStructure-with-Zig/',
  title: "Data Structure with Zig",
  description: "Learning Zig by writing data structures.",
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
          { text: '关于DSwZ', link: '/docs/00_introduction' },
          { text: 'Zig基础', link: '/docs/01_zig_basics' },
          { text: '数组Array', link: '/docs/02_array' },
          { text: '链表LinkedList', link: '/docs/03_linked_list' },
          { text: '栈Stack', link: '/docs/04_stack' },
          { text: '队列Queue', link: '/docs/05_queue' },
          { text: '哈希表Hash Table', link: '/docs/06_hash_table' },
          { text: '总结和回顾', link: '/docs/07_summary' },
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/IncorrectM/DataStructure-with-Zig' }
    ]
  }
})
