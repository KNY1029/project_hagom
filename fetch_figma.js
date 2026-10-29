const fs = require('fs');
const path = require('path');

const FIGMA_TOKEN = process.env.FIGMA_TOKEN;
const FILE_KEY = '7kGVGCGyX6DENFwDZZFt6Z';

async function main() {
    if (!FIGMA_TOKEN) {
        throw new Error('Set the FIGMA_TOKEN environment variable before running this script.');
    }
    console.log('Fetching Figma file...');
    const res = await fetch(`https://api.figma.com/v1/files/${FILE_KEY}?depth=2`, {
        headers: { 'X-Figma-Token': FIGMA_TOKEN }
    });
    
    if (!res.ok) {
        console.error('Failed to fetch file:', res.status, await res.text());
        return;
    }
    
    const data = await res.json();
    console.log(`Document Name: ${data.name}`);
    console.log(`Last Modified: ${data.lastModified}`);
    
    const frames = [];
    for (const page of data.document.children) {
        console.log(`\nPage: "${page.name}" (id: ${page.id})`);
        if (!page.children) continue;
        for (const child of page.children) {
            const bbox = child.absoluteBoundingBox || {};
            console.log(`  [${child.type}] "${child.name}" (id: ${child.id}) [${bbox.width || 0}x${bbox.height || 0}]`);
            if (child.type === 'FRAME' || child.type === 'COMPONENT' || child.type === 'SECTION') {
                frames.push({ id: child.id, name: child.name, type: child.type });
            }
        }
    }
    
    console.log(`\nTotal renderable frames found: ${frames.length}`);
    
    // Request images for all frames
    if (frames.length > 0) {
        const ids = frames.map(f => f.id).join(',');
        console.log('Requesting rendered PNGs for all frames...');
        const imgRes = await fetch(`https://api.figma.com/v1/images/${FILE_KEY}?ids=${ids}&scale=2&format=png`, {
            headers: { 'X-Figma-Token': FIGMA_TOKEN }
        });
        
        if (!imgRes.ok) {
            console.error('Image render request failed:', imgRes.status, await imgRes.text());
            return;
        }
        
        const imgData = await imgRes.json();
        const outputDir = path.join(__dirname, 'figma_frames');
        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }
        
        const downloaded = [];
        for (const frame of frames) {
            const imgUrl = imgData.images[frame.id];
            if (!imgUrl) continue;
            
            const sanitizedName = frame.name.replace(/[\/\\?%*:|"<>]/g, '_').trim();
            const filePath = path.join(outputDir, `${sanitizedName}_${frame.id.replace(':', '_')}.png`);
            
            console.log(`Downloading "${frame.name}"...`);
            const fileRes = await fetch(imgUrl);
            const buffer = Buffer.from(await fileRes.arrayBuffer());
            fs.writeFileSync(filePath, buffer);
            downloaded.push({ name: frame.name, id: frame.id, filePath });
        }
        
        console.log(`\nSuccessfully downloaded ${downloaded.length} frame images to: ${outputDir}`);
        fs.writeFileSync(path.join(outputDir, 'manifest.json'), JSON.stringify(downloaded, null, 2));
    }
}

main().catch(console.error);
