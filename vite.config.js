import { defineConfig } from 'vite'
import { viteStaticCopy } from 'vite-plugin-static-copy'
import coffee from 'vite-plugin-coffee'


export default defineConfig({
    server: {
        host: '127.0.0.1',
        port: '8080',
        strictPort: true
    },
    build: {
        chunkSizeWarningLimit: 1024 * 1024,
        outDir: '../www',
        minify: 'terser',
        emptyOutDir: true
        //sourcemap: boolean | 'inline' | 'hidden'
    },
    plugins: [
        viteStaticCopy({
            targets: [
                {
                    src: 'assets',
                    dest: '.'
                }
            ]
        }),
        coffee({
            jsx: false
        })
    ]
})
