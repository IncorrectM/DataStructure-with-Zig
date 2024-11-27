import { defineConfig } from 'vitepress'

/**
 * TODO: This is not working yet.
 */
export default defineConfig({
    themeConfig: {
        // https://vitepress.dev/reference/default-theme-config
        nav: [
          { text: 'Home', link: './' },
          { text: 'The Book', link: './docs' },
        ],
    
        sidebar: [
          {
            text: 'The Book',
            items: [
              { text: 'About DSwZ', link: './00_introduction' },
              { text: 'Basic Zig', link: './01_zig_basics' },
              { text: 'ArrayList', link: './02_array_list' },
              { text: 'LinkedList', link: './03_linked_list' },
              { text: 'Stack', link: './04_stack' },
              { text: 'Queue', link: './05_queue' },
              { text: 'Hash Table', link: './06_hash_table' },
              { text: 'Summary', link: './07_summary' },
            ]
          }
        ],
    
        socialLinks: [
          { icon: 'github', link: 'https://github.com/IncorrectM/DataStructure-with-Zig' }
        ]
    }
})