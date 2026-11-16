# GPA Calculator website

Web-based GPA calculator for SHSID, maintained by the Indexademics team (Ziqian Huang).

The original iOS app concept came from [Michel's GPA Calculator](https://github.com/michelg10/GPA-Calculator-3). The calculation rules are adapted from [okArelene's shsid-gpa-calculator](https://github.com/okArelene/shsid-gpa-calculator), and the Spring 2026 course catalog is sourced from [Panther114/panthergpa](https://github.com/Panther114/panthergpa).

### Why we moved away from the previous backend

The earlier backend and remote catalog were sourced from a contributor who stopped maintaining the catalog file. The original algorithms produced inconsistent or incorrect credit values (for example, science credits were under-counted compared to the SHSID scheduling guideline) and relied on an unmaintained remote `.gpa` file. This rewrite hosts the catalog inside the repository and uses the calculation rules from okArelene's audited implementation.

### Calculation scales

- **SHSID Weighted**: sum of `max(0, score + level offset) × credit` divided by total credits.
- **UC Unweighted**: standard 4.0 scale, counting only A–G eligible courses.
- **US Unweighted**: standard 4.0 scale with plus/minus (`A = 4.0`, `A- = 3.7`, `B+ = 3.3`, etc.).
- **Canada Unweighted**: 4.3 scale (`A+ = 4.3`, `A = 4.0`, `A- = 3.7`).
- **England Unweighted**: standard 4.0 scale.
- **Australia Unweighted**: 7-point scale (`HD = 7`, `D = 6`, `C = 5`, `P = 4`, `F = 0`).

These are planning estimates. Universities may recalculate GPA using their own rules.

### Key features
- Audited SHSID weighted GPA calculation using a local credit table
- US-style unweighted GPA estimate
- Support for Grade 6–12 presets, including AP/A-Level and IB tracks
- Course-name choices for elective modules
- Local catalog hosted in this repo (no dependency on external catalog files)
- Refined user interface
- Works on web and mobile

### Tech stack & usage
- **Frontend**: [Vue 3](https://vuejs.org/), [Vite](https://vitejs.dev/), [TypeScript](https://www.typescript.org/), [Tailwind CSS](https://tailwindcss.com/), [GSAP](https://gsap.com/)
- **Run locally**: [Node.js](https://nodejs.org/) (v18+), `brew install node`
    ```zsh
    git clone https://github.com/Ziqian-Huang0607/GPA-Calculator-Website.git
    cd GPA-Calculator-Website
    npm install
    npm run dev
    ```
    The local page [http://localhost:5173](http://localhost:5173) will automatically open in your browser.

### Support
- **Maintenance**: Indexademics team (Ziqian Huang)
- **Contact**: IDX TECH-Gordon Huang (mlfusion@outlook.com)
- **⚠️ Disclaimer**: This is an unofficial tool that is not affiliated with SHSID. All course information is based on the SHSID Course Catalog and is for reference purposes only. Course availability and policies are subject to change by the school administration.
