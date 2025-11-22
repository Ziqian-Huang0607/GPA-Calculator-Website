<img align="right" width="128" height="128" alt="SHSID Data Science Club" src="https://github.com/WillUHD/GPA-Calculator/blob/main/GPA%20Calculator/Assets.xcassets/GPACalcIcon.imageset/icon_128x128.png?raw=true" />

<div align="left">

GPA Calculator
=====================
calculate SHSID's curriculum GPAs with ease

---

### What's new
- Adapted to **SHSID's new 2025-2026 curriculum**
- Overhauled hard-coded presets with a dynamic system using `plist`s
  - this way, the course curriculum could be updated without having to update the app itself
  - curriculum stored [here](https://github.com/willuhd/gparesources/) and accessed via gh-proxy/EdgeOne internally
  - the app auto-checks for any valid curriculum updates at startup. If it fails, it will use the latest cached version which is Winter 2025
- Overhauled UI with module selection improvements
  - instead of having many module choices for G11, there are now 2: IB and everything else
  - the course logic is much smarter, allowing you to choose your modules dynamically
- Added a GPA pie viewer!
  - fun visualization of your GPA with fun animations
  - tap a subject to look at its insights (its own weighted GPA)
- Still kept Michel's legendary GPA algorithm and grades 6-8. 😎

---

### Demo

<img align="left" width="207" height="448" alt="IMG_2110" src="https://github.com/user-attachments/assets/914cbb10-b696-488c-a0e7-59de295e320e" />
<img align="right" width="207" height="448" alt="IMG_2106" src="https://github.com/user-attachments/assets/336db09c-e193-4673-8c1a-a25fff714278" />
<img align="left" width="207" height="448" alt="IMG_2107" src="https://github.com/user-attachments/assets/fdf59915-74ab-4558-9ec8-625d33eaa7a6" />
<img align="right" width="207" height="448" alt="IMG_2108" src="https://github.com/user-attachments/assets/cd0dc751-b62a-4fe2-8fdc-1954c252dc56" />


Auto-update at startup,  clear module selection logic, and a fun pie chart for you to reference. 

The new GPA Calc is just as accurate, while being improved all around. 

---

<div align="center">

> original made with ❤️ by michelg
>
> new changes made by willuhd
