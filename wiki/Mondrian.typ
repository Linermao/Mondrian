#import "@preview/zh-kit:0.1.0": * 
#import "@preview/zebraw:0.5.5": *

#show: zebraw
#show: doc => setup-base-fonts(
  doc,
  first-line-indent: 2em,
)

// 全局设定
#show figure.caption: set text(8.5pt)

#show heading: set block(
  spacing: 1.5em
)

#show link: set text(fill: rgb("#0a84ff")) 

#set page(
  numbering: "1"
)

#set par(
  justify: true,
  leading: 1.2em,
  spacing: 1.8em,
)

#set heading(
  numbering: "1.1",  
)

// 自定义模式

#let standout(body) = text(
  [_*#body*_]
)

#let standout_color(body) = text(
  fill: rgb("#0a84ff"),
  [_*#body*_]
)

#let codebox(lang, content) = rect(
  stroke: gray,
  fill: luma(245),
  radius: 2pt,
  inset: 8pt,
  [
    #{ 
      content 
    }
  ]
)


// 封面
#align(center)[
  #text(weight: "bold", size: 30pt)[杭州电子科技大学]
  \
  #text(size: 15pt, style:"italic")[Hangzhou Dianzi University]

  #text(weight: "bold", size: 36pt)[全国大学生计算机系统能力大赛]
  \
  #text(weight: "bold", size: 20pt)[Computer System Development Capability Competition]
  #linebreak()#linebreak()
  #image("introduce/HDU_logo.png", width: 190pt, fit: "contain")
  #par(leading: 1em, spacing: 10em)[  
    #text(
      weight: "bold",
      size: 28pt
    )[_Mondrian_]
    \
    #text(size: 14pt)[Wayland 协议下的平铺式桌面显示系统]
  ]

  #text(size: 14pt)[参赛人员： 林灿，吴悦怡，陈序]

  #text(size: 14pt)[2025 年 6 月]
]

#pagebreak()

#outline(depth: 2)

#pagebreak()

// 正文

= 项目概述

== 项目简介

本项目基于 Rust 语言与 Smithay 框架，通过 Wayland 协议实现了一个#standout_color[平铺式桌面显示系统]。
项目能够在裸机终端中自行初始化 DRM/KMS （Kernel Mode Setting） 图形管线，并通过 GBM (Generic Buffer Manager) 和 EGL（Embedded Graphics Library）建立 GPU 渲染上下文，使用 OpenGLES（OpenGL for Embedded Systems）进行硬件加速合成显示。启动后该 Compositor 接管系统图形输出，为客户端程序（如终端模拟器、浏览器）的 Wayland 提供显示服务。

#standout[“Beauty is the promise of happiness.” — Stendhal]

本项目秉持“优雅即力量”的设计哲学，致力于在系统结构与用户体验之间实现和谐平衡。无论是内部代码逻辑，还是外部交互呈现，都追求简洁、清晰而富有韵律的表达。

#figure(
  image("introduce/show1.png", width: 100%),
  caption: "项目运行效果演示图"
)

#figure(
  image("introduce/show2.png", width: 100%),
  caption: "项目运行效果演示图"
)


== 项目开发进度

项目自 3 月 25 日启动，初期集中精力对现有 Wayland 合成器框架（如 wlroots、Smithay 等）进行了调研与试验，结合项目可控性与扩展性要求，最终选择 #standout("Rust + Smithay") 作为核心技术栈。 

截至初赛阶段( 6 月 30 日 )，本项目已完成主要基础功能的开发，现已能够在主流 Linux 发行版上部署运行，具备日常使用的基本可用性。

截至决赛阶段（ 8 月 17 日 ）,本项目进一步实现了更多拓展功能，提升了“个性化定制”这一主题任务。开放多种配置接口提供给用户，用户也可以通过自己编写 shell 代码来实现快捷键的拓展响应事件。

系统现已支持多后端（DRM/KMS、Winit 等），显著提升了跨硬件和多环境适配能力。

在严格测试下，运行时崩溃情况基本被消除，系统具备良好的稳定性与容错机制。同时，本项目已集成 XWayland 支持，能够无缝运行绝大多数基于 X11 的传统 Linux GUI 应用。

实测环境下，90% 以上的常见桌面程序（如 Firefox、VS Code、GIMP、LibreOffice 等）均可稳定运行，确保用户在迁移到本系统时不牺牲原有生态体验。

这些改进标志着项目已从原型阶段迈向实用性，具备成为主力桌面环境的潜力。

在此基础上，为实现更高的性能、更强的可定制性以及更全面的兼容性，后续开发工作将聚焦于以下方向：

#align(center)[
  #table(
    columns: (2),
    align: center,
    inset: 5pt,
    
    [*多显示器管理*], [支持动态热插拔与独立配置],
    [*多输入设备支持*], [提升对触控板、手写板等外设的适配能力],
    [*更优秀的平铺布局方案*], [允许自由切换与自定义排版],
  )
]

#pagebreak()

== 项目核心功能

本项目支持在 TTY 模式下直接启动桌面显示系统，基于 DRM/KMS 原生渲染，无需依赖 X 服务或其他 Wayland 合成器进行消息转发。系统启动即加载 compositor，整体流程轻量高效。

通过内建的快捷键机制，用户可以快速启动常用应用，实现类似传统桌面环境的流畅体验。

项目设计充分考虑了日常使用场景，默认配置开箱即用，支持多任务管理、窗口操作与主题切换。

无需额外学习成本，普通用户也能轻松迁移，无割裂感，真正做到替代主流桌面环境。

== 项目特点

/ 代码体量: 累计新增 1w+ 行代码。

/ 全栈实现: 实现双后端架构：winit 支持桌面环境，tty 支持裸机直启，原生 DRM/KMS 渲染流程：直接控制 GPU 输出，无需依赖 X11 Server。

/ 数据结构与算法: 引入改造后的容器式二叉树布局方案，实现灵活的平铺与窗口变换；结合 SlotMap 实现节点的常数时间复杂度插入、删除与查找，极大提升动态性能。

/ 个性化与可编程定制能力: 使用统一配置文件控制主题样式、键位绑定、布局策略等，用户可通过 shell 脚本绑定快捷键，实现更复杂的自动化操作。

/ 动画与渲染: 自定义过渡动画与渲染逻辑，配合手写 GLSL shader，实现流畅、响应式的交互体验，视觉层次统一且精致。


#pagebreak()


= 赛题描述

== 赛题要求

=== 赛题名称

proj340 - 实现一个简单的平铺式管理的Wayland合成器

=== 赛题描述

实现一个 Wayland 合成器项目，使用平铺式的窗口布局策略来管理窗口的位置和大小，仅要求支持 XDG Shell 协议，对 XWayland 程序不做要求。

可参照任意已有的平铺式窗口管理器的行为，比如 i3、sway、hyprland 等

可使用基本的开发库作为底层实现，如 wlroots

=== 预期目标

程序运行后自动展示一个终端窗口，在终端窗口中输入命令可启动其它程序，新打开的Wayland窗口与已有的窗口无遮挡

== Linux 图形栈

人通过感知和操作与电脑交流，电脑通过硬件设备获取指令、给出反馈，再由系统软件进行翻译和执行。

整个系统围绕着 *“输入 → 处理 → 输出”* 的闭环进行工作，人类与计算机通过输入设备产生指令，经内核调度、用户态处理，再输出至显示设备，从而完成一次完整的交互过程。

#figure(
  image("introduce/linux图形人机交互.png", width: 100%),
  caption: "linux图形人机交互"
)

== Wayland 协议与 X11 协议

在 Linux 操作系统中，图形显示系统由多个层级组成，从底层的内核显卡驱动到用户态的图形协议，再到最终的 GUI 应用。整个图形栈主要包括以下几部分：

_*内核层（Kernel Space）：*_

/ DRM（Direct Rendering Manager）: 管理 GPU 资源与帧缓冲控制。
/ KMS（Kernel Mode Setting）: 用于设置显示模式，如分辨率、刷新率等。
/ GBM（Generic Buffer Management）: 用于创建与管理图形缓冲区。

_*图形服务器（Display Server）：*_

/ Xorg: X11 协议的标准实现。
/ Wayland Compositor: Wayland 协议的实现方，集成合成器、窗口管理器、输入系统。
/ 窗口管理器: 管理窗口的移动，缩放，堆叠关系等所有的窗口行为。

_*中间协议层*_

/ Mesa: 用户态 OpenGL/Vulkan 实现，提供图形驱动接口。
/ EGL: 抽象图形上下文与窗口系统之间的接口，衔接 OpenGL 与窗口系统。
/ 用户层协议（User Space Protocol）: 通信协议。

_*用户层*_

- GUI 应用程序，使用 Qt、GTK 等图形库开发。

#figure(
  image("introduce/linux图形栈.png", width: 70%),
  caption: "linux图形栈"
)

=== Wayland 协议

Wayland 是设计用于替代 X11 的现代图形协议，由 wayland.freedesktop.org 开发，强调简洁、安全、高性能。其基本架构如下：

Compositor so Display Server：

- 直接管理窗口、图像合成与缓冲交换。
- 处理输入事件，并直接分发到正确的客户端。
- 实现窗口管理逻辑（如平铺、浮动等）。
  
Client：

- 负责自行渲染窗口内容（通过 GPU 渲染或 CPU 绘图）。
- 使用 wl_surface 等原语将渲染结果提交给 Compositor。
- 与 Compositor 通过共享内存或 DMA Buffer 实现高效图像交换。

Protocols：

- 基于 Unix Domain Socket 通信，使用 wl_display 进行连接。
- 使用对象-事件模型（Object/Interface），类似面向对象远程调用。
- 无需往返确认，大部分请求为异步执行，提高响应效率。

#figure(
  image("introduce/wayland.png", width: 60%),
  caption: "wayland协议示意图"
)

=== X11 协议

X11 是诞生于 1984 年的图形窗口系统，其核心是 client - server 架构：

/ X Server: 运行在用户机器上，控制显示硬件，处理输入事件。
/ X Clients: 运行应用程序，向 X Server 请求窗口资源，并响应事件回调。

X11 协议支持网络透明性，即 X Client 和 X Server 可以运行在不同主机上。但其通信模型较为复杂：

- 每个窗口请求都需往返服务器确认（Round Trip），带来额外延迟。
- 图形渲染与窗口管理被分离为多个组件（如 WM、Compositor、Toolkit），难以协调。
- 输入事件先由 X Server 捕获，后由 Window Manager 转发，路径冗长且易出现冲突。

尽管历经多年优化，X11 的架构问题已难以适应现代图形性能与安全性的需求。

#figure(
  image("introduce/x11.png", width: 70%),
  caption: "x11协议示意图"
)


#pagebreak()


=== Wayland 协议的优势

相比 X11，Wayland 协议具有以下核心优势：

_*简洁的架构设计*_

Wayland 取消了中间代理（如 Xlib/XCB），让客户端直接负责渲染，Compositor 仅做图像合成与事件路由。这种 *单一控制点设计* 更加清晰易控。

_*异步通信模型*_

大多数请求为 异步非阻塞，大幅降低绘制窗口所需的 round-trip，提升性能表现，尤其在高帧率与多窗口场景下优势明显。

_*安全性与隔离性更好*_

Compositor 全面控制窗口焦点、输入与输出，不再暴露全局窗口信息。各客户端窗口互不可见（无法监听或操作其他窗口）。支持权限隔离（如输入抓取限制、屏幕截图权限控制等）。

_*动态扩展能力强*_

Wayland 协议采用模块化设计，核心协议只定义基础对象（如 wl_surface, wl_output），其他功能由 扩展协议（Protocol Extensions） 提供，例如：


#align(center)[
  #table(
    columns: (2),
    align: center,
    inset: 5pt,
    
    [*xdg-shell*], [提供桌面窗口接口（如 toplevel/popup）],
    [*wlr-layer-shell*], [支持桌面元素（如面板、壁纸）],
    [*xdg-output*], [扩展输出信息],
    [*pointer-gestures*], [添加手势支持],
  )
]

_*原生合成支持*_

每个窗口的图像由 Client 渲染后交给 Compositor 直接合成，因此减少了冗余图层绘制流程，更容易实现视觉效果（圆角、阴影、动画），支持真正的无撕裂与高刷新率渲染。


#pagebreak()


== 平铺式布局管理

传统的桌面环境普遍采用堆叠式（Stacking）窗口管理模型，其核心思想是通过层叠多个可自由移动和缩放的窗口，来完成用户的窗口组织。窗口的可见性与交互依赖于 Z 轴层级与遮挡关系。在窗口数量增多、频繁切换任务时，这种模型容易导致空间浪费、管理混乱、用户认知负担增大，不利于快速切换和管理窗口。

#figure(
  image("introduce/stack.png", width: 100%),
  caption: "堆叠式布局示意图（来自GNOME）"
)

#figure(
  image("introduce/tiled.png", width: 100%),
  caption: "平铺式布局示意图（来自GNOME）"
)

平铺式（Tiling）窗口管理是一种高度结构化的布局方式，屏幕被划分为若干区域，每个窗口占据一个不重叠的矩形区域，并根据特定的布局算法自动排列。其核心原则是：

#standout_color[所有活动窗口在空间上无重叠，完全平铺填充屏幕空间。]

/ 窗口自动布局: 每当有新窗口创建，它不会以浮动方式出现，而是根据当前焦点窗口的位置与所选布局算法（如垂直分裂、水平分裂、主从结构等）自动插入到屏幕分区中。
/ 无重叠区域，最大化利用空间: 所有窗口矩形区域互不重叠，窗口大小由布局决定而非用户拖拽（当然存在平铺式与堆叠式一同使用的情况，允许鼠标进行一定的操作），避免空间浪费。
/ 键盘优先交互: 平铺管理器强调键盘操控，通过快捷键进行窗口聚焦、移动、交换、调整布局比例等操作，效率远高于传统的鼠标驱动方式。
/ 一致性与可预测性: 所有布局变化均可通过布局算法精确复现，不依赖“拖拽”或“随机叠放”这种不可重现的行为，便于自动化与脚本控制。


#pagebreak()



= 项目设计与实现

== 技术选型

_Mondrian_ 的核心目标是实现一个 #standout[面向未来的、结构可控的] 平铺式桌面环境，因此我们选择了 Rust 作为主要开发语言，并基于 Smithay 框架进行构建。这一组合在性能、可靠性、安全性和协议支持方面表现出极高的适配性。

== Smithay

Smithay 是一个专为构建 Wayland 合成器而设计的 Rust 框架，提供了协议实现、后端抽象、渲染集成等基础模块。它不是一个完整的 window manager，而是一个合成器构建工具箱。

#figure(
  image("introduce/smithay.png", width: 100%),
  caption: "smithay github 主页截图"
)

其优势主要体现在以下几个方面：

/ 模块化设计: Smithay 拆分为多个可选模块，如 wayland-backend, wayland-protocols, input, output 等。
/ Wayland 协议支持广泛: 支持核心协议如 wl_compositor, wl_seat, xdg-shell，并集成 xdg-output, layer-shell, wlr-protocols 等常见扩展。可以在合成器层自由定制协议行为，例如限制窗口行为、插入布局钩子等。
/ 后端抽象能力: 支持多个图形后端（EGL, GLES2, WGPU）、输入后端（Winit、libinput）与输出设备管理（DRM/KMS、virtual output）。允许在不同平台（如嵌入式、TTY、X11）运行，底层支持度高。
/ 灵活可插拔架构: 不像 Weston 或 wlroots 那样强绑定窗口管理逻辑，Smithay 允许合成器设计者自行定义事件循环、窗口模型与渲染策略，非常适合实现平铺式或动态布局系统。
/ 社区活跃、长期演进: Smithay 拥有稳定的维护团队，与 Mesa、wlroots 社区保持良好协作，能持续跟进最新的 Wayland 标准与实践。


== Rust

Rust 是一门强调安全性与并发性能的系统级语言，具备以下几个关键优势，使其特别适合构建图形协议栈与桌面管理器：

/ 内存安全（Memory Safety）: Rust 通过所有权系统与静态借用检查器，在编译期保障内存访问合法性，杜绝 Use-After-Free、空指针解引用等常见错误，无需垃圾回收器。对于一个合成器来说，这意味着在处理 surface 生命周期、buffer 引用、输入事件时可以避免大量运行时错误。
/ 数据并发性（Fearless Concurrency）: Rust 支持无数据竞争的并发操作，允许我们在后台异步处理输入事件、合成器状态更新与渲染流程，确保交互响应流畅且线程安全。
/ 丰富的生态与 tooling: cargo、clippy、rust-analyzer 等工具提供了出色的开发体验和持续集成支持，便于维护大型项目。与 Mesa、WGPU、EGL 等图形库的绑定日趋成熟，为集成硬件加速渲染提供了良好基础。

#pagebreak()

== Wayland 协议交互细节（The Wayland Protocol#cite(<wayland_design_patterns>)）

=== Unix Socket

迄今为止，所有的 Wayland 实现均通过 Unix Socket 工作。 这有个很特别的原因：文件描述符消息。 Unix Socket 是最实用的跨进程文件描述符传输方法，这对大文件传输（如键盘映射、像素缓冲区、剪切板）来说非常必要。 理论上其它传输协议（比如 TCP）是可行的，但是需要开发者实现大文件传输的替代方案。

为了找到 Unix Socket 并连接，大部分实现要做的事和 libwayland 所做的一样：

1. 如果 WAYLAND_SOCKET 已设置，则假设父进程已经为我们配置了连接，将 WAYLAND_SOCKET 解析为文件描述符。
2. 如果 WAYLAND_DISPLAY 已设置，则与 XDG_RUNTIME_DIR 路径连接，尝试建立 Unix Socket。
3. 假设 Socket 名称为 wayland-0 并连接 XDG_RUNTIME_DIR 为路径，尝试建立 Unix Socket。
4. 失败放弃。

=== 接口与事件请求

Wayland 协议通过发出作用于对象的请求和事件来工作。 每个对象都有自己的接口，定义了可行的请求事件以及对应的签名。wl_surface 是最简单的一个接口。

Surface 是可以在屏幕上显示的像素区域， 是我们构建应用程序窗口之类的东西的基本元素之一。 它有个请求名为“damage”（损坏），客户端发送这个请求表示某个 surface 的某些部分发生了变化，需要重绘。 下面是 wire 中的一个 damage 消息的带注释示例（16 进制）：

```bash
0000000A    对象 ID (10)
00180002    消息长度 (24) 和请求操作码 (2)
00000000    X 坐标       (int): 0
00000000    Y 坐标       (int): 0
00000100    宽度         (int): 256
00000100    高度         (int): 256
```

这是 session 会话的小片段：surface 已经提前分配，它的 ID 为 10。 当服务端收到这条消息后，服务端会查找 ID 为 10 的对象，发现它是一个 wl_surface 实例。 基于此，服务端用请求的 opcode 操作码 2 查找请求的签名。 然后就知道了接下来有四个整型作为参数，这样服务器就能解码这条消息，分派到内部处理。

请求是从客户端发送到服务端，反之，服务端也可以给客户端广播消息，叫做“事件”。 例如，其中一个事件是 wl_surface 的 enter 事件，在 surface 被显示到指定的 output 时，服务端将发送该事件 （客户端可能会响应这一事件，比如为 HiDPI 高分屏调整缩放的比例因数）。

=== 原子性

Wayland 协议设计规范中最重要的是原子性。 Wayland 的一个既定目标是 "每帧都完美"。 为此，大多数接口允许以事务的方式更新，使用多个请求来创建一个新的表示状态，然后一次性提交所有请求。 例如，以下几个属性可以在 wl_surface 上配置：

- 附加的像素缓冲区
- 需要重新绘制的变更区域
- 出于优化而设置为不透明的区域
- 可接受输入事件的区域
- 变换，比如旋转 90 度
- 缓冲区的缩放比例，用于 HiDPI

接口为这些配置提供了许多独立的请求，但它们都处于挂起状态（pending）。 仅当发送提交(commit)请求时，挂起状态才会合并到当前状态（current）。 从而可以在单帧内，原子地更新所有这些属性。 结合其他一些关键性的设计决策，Wayland 合成器可以在每一帧中都完美地渲染一切，没有撕裂或更新一半的窗口，每个像素都在它应在的位置，静静地显示。

=== 共享内存缓冲区

从客户端获取像素到混成器最简单，也是唯一被载入 wayland.xml 的方法，就是 wl_shm ——共享内存。简单地说，它允许你为混成器传输一个文件描述符到带有 MAP_SHARED 的内存映射（mmap），然后从这个池中共享像素缓冲区。添加一些简单的同步原语，以防止缓冲区竞争，然后你就有了一个可行且可移植的解决方案。

=== xdg shell

XDG (cross-desktop group) shell 是 Wayland 的一个标准扩展协议，描述了应用窗口的语义。它定义了两个 wl_surface 角色："toplevel" 用于你的顶层应用窗口；"popup" 则用于诸如上下文菜单、下拉菜单、工具提示等等——它们是顶层窗口的子集。有了这些，你可以将其归结于一个树状结构，顶层是根，弹出式或附加式窗口处于顶层的子叶上。该协议还定义了一个定位器接口，用于辅助定位弹窗，并提供有关窗口周围事物的那些信息。

在 xdg-shell 领域内的表面被称为 xdg_surfaces，这个接口带来了两种 XDG 表面所共有的功能——toplevels 和 popups（也即之前提到的顶层窗口和弹窗）。每种 XDG 表面的语义仍然不同，所以必须通过一个额外的角色来明确指定它们。

xdg_surface 接口提供了额外的请求来分配更具体的 popup 和 toplevel 角色。一旦我们将一个全局对象绑定到全局接口 xdg_wm_base，我们就可以使用 get_xdg_surface 请求来获得一个 wl_suraface。

xdg-surface 最重要的 API 就是 configure 和 ack_configure 这一对。Wayland 的一个目标是让每一帧都完美呈现，这意味着任何一帧都没有应用了一半的状态变化（原子性，避免画面撕裂），为了实现这个目标，我们必须要在客户端和服务端之间同步这些变化。对于 XDG 表面来说，这对消息（这两个 API 传递的内容）正是实现这一目的的机制。

当来自服务端的事件通知你配置（或重新配置）一个表面时，将它们设置到一个待定状态。当一个 configure 事件到来时，会应用先前准备好的变化，使用 ack_configure 来确定你已经这样做了，然后渲染并提交一个新的帧。

以下步骤将会从零开始创建一个屏幕上的窗口：

1. 绑定到 wl_compositor 并使用它来创建一个 wl_surface
2. 绑定到 xdg_wm_base 并用它为你的 wl_surface 创建一个 xdg_surface
3. 通过 xdg_surface.get_toplevel 从 xdg_surface 创建一个 xdg_toplevel
4. 为 xdg_surface 创建一个监听器，并且等待 configure 事件的发生。
5. 绑定到你选择的缓冲区分配机制（如 wl_shm），并分配一个共享缓冲区，然后将你要显示的内容渲染后传入。
6. 使用 wl_surface.attach 将 wl_buffer 附加到 wl_surface 上。
7. 使用 xdg_surface.ack_configure 把 configure 的序列信息传给它，确认你已经准备好了一个合适的帧。
8. 发送一个 wl_surface.commit 请求。


#pagebreak()


== 项目最小实现

=== 架构概览

Smithay 采用 _calloop_ 作为主事件循环框架，其优势在于：

- 可插拔式事件源管理（source registration）
- 高性能的非阻塞式事件分发
- 原生支持定时器、通道等常用异步通信模型

Smithay 为 Winit 后端提供了优秀的兼容模式，可以很方便的进行开发。

=== EventLoop 事件分发机制

在基于 Smithay 构建的 Wayland Compositor 中，事件循环（EventLoop）是整个系统运行的核心。所有的输入、输出、客户端请求、时间驱动逻辑，乃至后台任务的调度都依赖于该机制完成事件的监听与响应。

_*定义*_

在 `main` 函数中定义一个 `EventLoop` 主体非常简单，直接调用相关的库函数：

```rust
use smithay::reexports::calloop::EventLoop;
let mut event_loop: EventLoop<'_, State> = EventLoop::try_new().unwrap();
```

在这里，`State` 类型是全局状态结构体，由我们自己定义，目前暂时不谈论细节，你只需知道这个结构体管理所有的程序状态即可。

通过获取 `LoopHandle` 就来执行事件的插入，删除与执行操作：

```rust
event_loop
    .handle() // LoopHandle
    .insert_source(input_backend, move |event, &mut metadata, state| {
        // action
    })?;
```

在这里，我们通过 `handle()` 函数获取操作入口，使用 `insert_source` 函数来注册 `EventSource`，其会将一个监听对象添加到主循环中，并且绑定一个处理函数（回调闭包），每当事件产生时，就会调用这个函数。

事件循环可以绑定多个事件源，常见类别如下：

#align(center)[
  #table(
    columns: (3),
    align: center,
    inset: 5pt,
    
    [*类型*], [来源], [示例事件],
    [*输入设备*], [libinput], [PointerMotion、KeyboardKey 等],
    [*图形输出*], [DRM/KMS, Winit], [热插拔、显示尺寸改变],
    [*Wayland 客户端*], [WaylandSocket], [请求窗口创建、buffer attach],
    [*定时器*], [calloop Timer], [动画帧调度、超时],
    [*自定义通道*], [calloop Channel], [后台任务返回、信号触发],
  )
]

在 `insert_source` 中绑定的回调闭包具有以下签名：

```rust
FnMut(E, &mut Metadata, &mut State)
```

- `E`: 来自事件源的事件本体，类型依赖于事件源。
- `Metadata`: 事件元信息（通常是 `calloop::generic::GenericMetadata`），包含事件触发时的底层 I/O 状态，例如可读/可写标志。大多数情况下你可以忽略该参数，除非你要做更底层的 I/O 操作。
- `State`: 传入的全局状态对象，是你自定义的全局状态结构，也就是一开始定义的类型 `EventLoop<'_, State>` 中的 `State`。

最容易理解的就是客户端连接请求的事件处理：

```rust
let source = ListeningSocketSource::new_auto().unwrap();
let socket_name = source.socket_name().to_string_lossy().into_owned();
loop_handle
    .insert_source(source, move |client_stream, _, state| {
        state
            .display_handle
            .insert_client(client_stream, Arc::new(ClientState::default()))
            .unwrap();
    })
    .expect("Failed to init wayland socket source.");
```

`Wayland` 是一个基于 `UNIX 域套接字（UNIX domain socket）` 的通信协议，`Client` 与 `Compositor` 之间的所有协议交互，都是通过一个共享的本地套接字进行的。

`ListeningSocketSource::new_auto()` 会自动创建一个新的 `UNIX 域套接字`，并监听客户端连接请求。默认在 `/run/user/UID/` 下创建 `socket` 文件，例如 `wayland-0`。本地调试时我们需要设置环境变量 `WAYLAND_DISPLAY=wayland-0` 来绑定测试的 `Compositor`。

当有客户端连接或请求发生时，对应的事件将触发该回调闭包，并调用 `.display_handle.insert_client` 以执行客户端初始化、资源绑定或协议处理等逻辑。

详细的创建内容在 *Client事件源* 篇会详细讲解。

_*事件执行*_

此前我们只是将需要监听的事件源和需要执行的函数内容加入到了 `EventLoop` 中，但还未真正的下达指令 - 你可以开始监听了，因此，我们还需要以下代码来真正开启循环：

```rust
event_loop
    .run(None, &mut state, move |_| {
        //  is running
    })
    .unwrap();
```

此时，我们可以解答在事件源插入中遗留的问题了，可变借用是此时才被传入其中的，顺序上也许会让人疑惑，但这就是 Rust 的“延迟状态绑定”机制的奇妙之处。

在调用 `insert_source` 时，事件循环尚未开始运行，只是注册了事件源与回调；

所有回调的 `state` 参数类型由 `EventLoop<T>` 的泛型 T 决定（例如我们定义的 `State`），但值本身尚未存在；

直到调用 `run(&mut state, ...)` 这一刻，`state` 的实际引用才被注入到事件循环中；

从此刻开始，`calloop` 内部在每次事件分发时，才会将这个 `&mut T` 传入闭包中。

它确保了事件循环中所有 `state` 的使用都在 `run()` 的生命周期范围内发生，且绝不会出现悬垂引用或数据竞争。

至此，核心的框架就已经被我们解决了，接下来就是真正的进行对不同事件源的处理。


=== Client 事件源

在 `Wayland` 协议中，客户端的渲染行为是以 `wl_surface` 为基本单位的。每一个客户端窗口本质上都是在创建并提交一个或多个 `surface`，而这些 `surface` 的行为则由其绑定的角色（如 `xdg_toplevel` 或 `xdg_popup` ）所定义。

在之前我们已经见过以下的代码：

```rust
let source = ListeningSocketSource::new_auto().unwrap();
let socket_name = source.socket_name().to_string_lossy().into_owned();
loop_handle
    .insert_source(source, move |client_stream, _, state| {
        state
            .display_handle
            .insert_client(client_stream, Arc::new(ClientState::default()))
            .unwrap();
    })
    .expect("Failed to init wayland socket source.");
```

这段代码创建了一个新的 `UNIX 域套接字`，监听客户端的连接请求。`Wayland` 是一个 `拉模型（pull model）`，客户端不会主动创建窗口，而是从服务端请求对象并获得引用。其中具体的请求过程如下：

- 连接 `display socket`：客户端连接 `compositor` 暴露的 `UNIX 域套接字`（如 `/run/user/1000/wayland-0`）。
- 绑定 `wl_registry`：连接后，客户端首先获取 `wl_display` 提供的 `wl_registry` `对象，它包含了compositor` 所支持的所有全局对象（如 `wl_compositor`、`wl_shm`、`xdg_wm_base` 等）。
- 获取 `wl_compositor` 接口：客户端通过 `wl_registry.bind(...)` 获得 `wl_compositor` 接口，允许创建 `wl_surface`。
- 创建 `wl_surface`：客户端通过 `wl_compositor.create_surface()` 调用，获得一个新的 `surface` 例，这是所有图形内容提交的基础。
- 绑定 `xdg_surface` 与角色：随后，客户端使用 `xdg_wm_base.get_xdg_surface(surface)` 创建`xdg_surface`，再通过 `get_toplevel()` 等调用为其赋予具体角色。
- 随后就可以通过 `surface.commit()` 向 `compositor` 传递需要显示的内容。

看到如此多的协议信息，首先有必要介绍一下 `xdg-shell` 协议。

=== xdg-shell 协议实现

#link("https://wayland.app/protocols/xdg-shell")[protocol link: XDG shell protocol | Wayland Explorer]

在 `Wayland` 协议体系中，`xdg-shell` 是一项核心协议，扩展了基础的 `wl_surface` 对象，使其能够在桌面环境下扮演窗口的角色。它是现代 `Wayland` 桌面应用窗口管理的标准，涵盖了顶层窗口、弹出窗口、窗口状态控制等一系列行为。

#figure(
  image("introduce/xdg_shell.png", width: 70%),
  caption: "xdg_shell协议示意图"
)

`xdg-shell` 协议主要围绕以下对象展开：

- `xdg_wm_base`：客户端首先通过 `wl_registry` 获取 `xdg_wm_base` 接口。
- `xdg_surface`：通过 `xdg_wm_base.get_xdg_surface(wl_surface)`，客户端将一个基础的 `wl_surface` 与 `xdg_surface` 关联起来。
- `xdg_toplevel`：通过 `xdg_surface.get_toplevel()`，该 `surface` 被赋予了「顶层窗口」的角色。
- `xdg_popup`：替代 `toplevel`，它赋予窗口「弹出窗口」的角色，通常用于菜单、右键栏等临时 UI。

一个 `wl_surface` 只能被赋予一个角色，即它要么是 `xdg_toplevel`，要么是 `xdg_popup`，不能同时拥有或重复绑定。

我们可以这样理解：`wl_surface` 是原始画布，`xdg_surface` 是语义包装器，`xdg_toplevel` 或 `xdg_popup` 是具体的行为描述者。

=== configure / ack 机制

在 `xdg-shell` 协议中，一个非常重要的机制就是「双向确认机制」：

在有修改需求的时候，`compositor` 发起 `configure` 事件，告知客户端窗口大小、状态变更请求，客户端必须回应 `ack_configure`，明确表示接收到该配置并将进行重绘，只有在 `ack` 后，客户端提交的 `surface.commit()` 内容才会被正式展示。

这种机制是 `Wayland` 相对于传统 `X11` 的一大改进点，确保了服务端与客户端状态始终一致，*不会出现窗口闪动或布局错乱*。

```rust
use smithay::{
    delegate_xdg_shell,
    wayland::shell::xdg::{XdgShellHandler, XdgShellState},
};

// init in state struct
{
    ...
    let xdg_shell_state = XdgShellState::new::<Self>(&display_handle);
    ...
}

impl XdgShellHandler for State {
    fn xdg_shell_state(&mut self) -> &mut XdgShellState {
        //
    }

    fn new_toplevel(&mut self, surface: ToplevelSurface) {
        //
    }

    fn new_popup(&mut self, surface: PopupSurface, _positioner: PositionerState) {
        //
    }

    fn reposition_request(
        &mut self,
        surface: PopupSurface,
        positioner: PositionerState,
        token: u32,
    ) {
        //
    }

    fn toplevel_destroyed(&mut self, surface: ToplevelSurface) {
        //
    }

    fn move_request(&mut self, surface: ToplevelSurface, seat: wl_seat::WlSeat, serial: Serial) {
        //
    }

    fn resize_request(
        &mut self,
        surface: ToplevelSurface,
        seat: wl_seat::WlSeat,
        serial: Serial,
        edges: xdg_toplevel::ResizeEdge,
    ) {
        //
    }

    fn grab(&mut self, _surface: PopupSurface, _seat: wl_seat::WlSeat, _serial: Serial) { }
}
delegate_xdg_shell!(State);
```

设置 `xdg-shell` 协议的相关代码也非常简单，只需要使用 `smithay` 提供的框架即可。具体函数内部实现的方法，参考基础框架代码。

至此，我们已经完成了核心的 `surface` 分配机制，相当于给画家提供了画板，还设置了画板最后展出的场馆 - `toplevel` 或 `popup` 。


=== input 事件源

`compositor` 的核心职责之一是处理来自用户的输入事件，如鼠标移动、按键、触摸交互等。而这些输入事件的来源方式依赖于 `compositor` 所使用的后端类型。`Smithay` 提供了多个后端支持，其中包括：

- `winit` 后端：通常用于开发阶段，快速接入图形窗口系统并获取输入；
- `TTY` + `libinput` 后端：更贴近生产环境，直接从内核设备文件读取输入事件，适用于 DRM/KMS 渲染路径。

==== 使用 winit 后端的 input 事件源

在 `winit` 模式下，`Smithay` 提供了高度集成的 `WinitInputBackend` 类型，开发者可以非常方便地将其作为事件源插入 `EventLoop` 中，例如：

```rust
event_loop
    .handle()
    .insert_source(winit_backend, move |event, _, state| {
        state.process_input_event(event);
    })?;
```

`winit` 后端封装了窗口事件与输入事件，并提供统一的接口输出 `InputEvent`。`Smithay` 内部支持对这些事件进行标准化转换，如：

- `PointerEvent`
- `KeyboardEvent`
- `TouchEvent`

通常在 `state.process_input_event` 函数中进行分发，`Smithay` 的 `seat` 抽象会帮助我们自动处理焦点跟踪、输入分发、键盘修饰等细节。

```rust
use smithay::backend::{delegate_seat, input::{Seat, SeatHandler, SeatState}};

// init in state struct
{
    let mut seat_state = SeatState::new();
    let seat_name = String::from("winit");
    let mut seat: Seat<Self> = seat_state.new_wl_seat(display_handle,seat_name);
}

impl SeatHandler for State {
    type KeyboardFocus = WlSurface;
    type PointerFocus = WlSurface;
    type TouchFocus = WlSurface;

    fn seat_state(&mut self) -> &mut SeatState<State> {
        //
    }

    fn cursor_image(
        &mut self,
        _seat: &Seat<Self>,
        image: smithay::input::pointer::CursorImageStatus,
    ) {
        //
    }

    fn focus_changed(&mut self, seat: &Seat<Self>, focused: Option<&WlSurface>) {
        //
    }
}
delegate_seat(State);
```

==== 使用 TTY 后端的 input 事件源

在没有图形服务器支持的*裸机环境*下，我们通常使用 `TTY` 作为图形输出后端，并结合 `libinput` 获取来自 `/dev/input` 的事件。此时输入处理方式较为底层，需要我们显式构造事件源：

```rust
let libinput_context = Libinput::new_with_udev(...);
let input_backend = LibinputInputBackend::new(libinput_context, seat, ...);
```

与 `winit` 不同，`libinput` 后端需要手动处理权限和 `seat` 初始化，但优点在于：

- 支持更精细的输入设备管理；
- 能兼容热插拔、多用户、多 `seat`；
- 更贴近真实硬件行为（如 VT 切换、KMS 挂载）；

事件注册仍然可以通过 `insert_source` 完成。

```rust
event_loop
    .handle()
    .insert_source(input_backend, move |event, _, state| {
        state.process_input_event(event);
    })?;
```

无论是 `winit` 还是 `TTY` 模式，输入事件的处理流程基本保持一致：

- 后端产生 `InputEvent`；
- 事件被传入 `compositor` 的状态处理器；
- `Smithay` 的 `Seat` 接口会自动更新焦点状态、生成 `Wayland` 协议事件；
- 若存在活跃客户端，事件会通过 `wl_pointer`、`wl_keyboard`、`wl_touch` 等接口传输至客户端。

具体的状态如： `InputEvent::Keyboard`，`InputEvent::PointerMotion` 等这里不再详细讲解，具体参考基础框架代码内容。

至此，我们就得到了一个简单的，可以响应客户端请求，并且支持鼠标，键盘操作的简易 Wayland Compositor。

#pagebreak()

== 输入设备事件监听

在 _Mondrian_ 中，我们实现了一个轻量且可扩展的全局快捷键匹配系统，用于：

- 启动应用程序（如打开终端）
- 执行窗口管理指令（如聚焦切换、窗口平铺方向调整）
- 支持用户自定义的命令绑定

=== 快捷键的输入流程概览

- Wayland 中键盘事件由 `wl_keyboard`（或 `xkb`）协议触发，最终通过 `InputManager` 处理。
- 快捷键响应链：  
  `键盘事件 → 按键状态判定（按下/释放） → 匹配组合键 → 执行对应指令`

=== 正则匹配：解析指令或快捷命令

用户定义的快捷指令存储在 /keybindings.conf 文件中，例如：

```json
# /keybindings.conf
bind = Super_L+f, command, "firefox"
bind = Super_L+1, exec, "workspace-1"
```

为了支持复杂的指令格式，我们在命令解析阶段引入了 Rust 的 `regex` 正则库：

```rust
let re =
    // bind = Ctrl + t, command, "kitty"
    // bind = Ctrl + 1, exec, "func1"
    Regex::new(r#"(?m)^\s*bind\s*=\s*([^,]+?),\s*(command|exec),\s*"([^"]+)"(?:\s*#.*)?$"#)
        .unwrap();

for cap in re.captures_iter(&content) {
    let keybind = &cap[1]; // Ctrl+t / Alt+Enter
    let action = &cap[2]; // exec / command
    let command = &cap[3]; // kitty / rofi -show drun
    ...
}
```

对于解析指令与快捷命令，我们使用 `KeyAction` 存储命令内容，对于解析指令，另外使用 `FunctionEnum` 进行存储，方便后续使用：

```rust
#[derive(Debug)]
pub enum FunctionEnum {
    SwitchWorkspace1,
    SwitchWorkspace2,
    InvertWindow,
    Expansion,
    Recover,
    Quit,
    Kill,
    Json,
    Up(Direction),
    Down(Direction),
    Left(Direction),
    Right(Direction),
}

#[derive(Debug)]
pub enum KeyAction {
    Command(String, Vec<String>),
    Internal(FunctionEnum),
}
```

完整的快捷键识别与匹配，对于 Ctrl Shift 等键，将其设置为左右两键均可触发，保证后续识别执行正确：

```rust
impl InputManager{
    fn load_keybindings(path: &str) -> anyhow::Result<HashMap<String, KeyAction>> {
        let content = fs::read_to_string(path).anyhow_err("Failed to load keybindings config")?;
        let mut bindings = HashMap::<String, KeyAction>::new();
        let re =
            // bind = Ctrl + t, command, "kitty"
            // bind = Ctrl + 1, exec, "func1"
            Regex::new(r#"(?m)^\s*bind\s*=\s*([^,]+?),\s*(command|exec),\s*"([^"]+)"(?:\s*#.*)?$"#)
                .unwrap();

        let modifier_map: HashMap<&str, Vec<&str>> = [
            ("Ctrl", vec!["Control_L", "Control_R"]),
            ("Shift", vec!["Shift_L", "Shift_R"]),
            ("Alt", vec!["Alt_L", "Alt_R"]),
            ("Esc", vec!["Escape"]),
            ("[", vec!["bracketleft"]),
            ("]", vec!["bracketright"]),
            (",", vec!["comma"]),
            (".", vec!["period"]),
            ("/", vec!["slash"]),
            (";", vec!["semicolon"]),
            (".", vec!["period"]),
            ("'", vec!["apostrophe"]),
        ]
        .into_iter()
        .collect();

        for cap in re.captures_iter(&content) {
            let keybind = &cap[1]; // Ctrl+t / Alt+Enter
            let action = &cap[2]; // exec / command
            let command = &cap[3]; // kitty / rofi -show drun

            let keys: Vec<String> = keybind
                .split('+')
                .map(|key| {
                    if let Some(modifiers) = modifier_map.get(key) {
                        modifiers.iter().map(|m| m.to_string()).collect()
                    } else {
                        vec![key.to_string()]
                    }
                })
                .multi_cartesian_product()
                .map(|combination| combination.join("+"))
                .collect();

            for key in keys {
                let action_enum = match action {
                    "command" => {
                        let mut parts = command.split_whitespace();
                        let cmd = parts.next().unwrap_or("").to_string();
                        let args: Vec<String> = parts.map(|s| s.to_string()).collect();

                        KeyAction::Command(cmd, args)
                    }
                    "exec" => {
                        let internal_action = match command.trim() {
                            "workspace-1" => FunctionEnum::SwitchWorkspace1,
                            "workspace-2" => FunctionEnum::SwitchWorkspace2,
                            "invert" => FunctionEnum::InvertWindow,
                            "recover" => FunctionEnum::Recover,
                            "expansion" => FunctionEnum::Expansion,
                            "quit" => FunctionEnum::Quit,
                            "kill" => FunctionEnum::Kill,
                            "json" => FunctionEnum::Json,
                            "up" => FunctionEnum::Up(Direction::Up),
                            "down" => FunctionEnum::Down(Direction::Down),
                            "left" => FunctionEnum::Left(Direction::Left),
                            "right" => FunctionEnum::Right(Direction::Right),
                            _ => {
                                tracing::info!(
                                    "Warning: No registered function for exec '{}'",
                                    command
                                );
                                continue;
                            }
                        };
                        KeyAction::Internal(internal_action)
                    }
                    _ => continue,
                };

                bindings.insert(key.to_string(), action_enum);
            }
        }

        #[cfg(feature = "trace_input")]
        for (key, action) in &bindings {
            tracing::info!(%key, action = ?action, "Keybinding registered");
        }

        Ok(bindings)
    }
}
```

=== Keymap 映射：输入事件的键码与组合键识别

使用 `xkbcommon` 配合 `Smithay::input`，可以将原始键码解析为用户理解的键位，如：

- 原始：`keycode = 38`（硬件码）

- 解析后：`keysym = "a"`

一般快捷键均由功能键发起，为了确保识别正确，我们定义了一个优先级 map，用于设置功能键优先于所有字母键。

```rust
...
// priority: Ctrl > Shift > Alt
let priority_map: HashMap<String, i32> = [
    ("Super_L", 0),
    ("Control_L", 1),
    ("Control_R", 1),
    ("Shift_L", 2),
    ("Shift_R", 2),
    ("Alt_L", 3),
    ("Alt_R", 3),
]
.into_iter()
.map(|(k, v)| (k.to_string(), v))
.collect();
...
```

在按下某个按键时，通过 `keysym_get_name()` 得到硬件码对应的可读 ASCII 码，并且将其按照优先级排序后，排列成当前按下键，交与 `action_keys()` 函数处理快捷键事件。

```rust
...
KeyState::Pressed => {
    let mut pressed_keys_name: Vec<String> =
        keyboard.with_pressed_keysyms(|keysym_handles| {
            keysym_handles
                .iter()
                .map(|keysym_handle| {
                    let keysym_value = keysym_handle.modified_sym();
                    let name = keysym_get_name(keysym_value);
                    if name == "Control_L" {
                        #[cfg(feature = "trace_input")]
                        info!("mainmod_pressed: true");
                        data.input_manager.set_mainmode(true);
                    }
                    name
                })
                .collect()
        });
    pressed_keys_name
        .sort_by_key(|key| priority_map.get(key).cloned().unwrap_or(3));
    let keys = pressed_keys_name.join("+");
    #[cfg(feature = "trace_input")]
    info!("Keys: {:?}", keys);
    data.action_keys(keys, serial);
}
...
...
pub fn action_keys(&mut self, keys: String, serial: Serial) {
    let keybindings = self.input_manager.get_keybindings();
    if let Some(command) = keybindings.get(&keys) {
        match command {
            KeyAction::Command(cmd, args) => {
                #[cfg(feature = "trace_input")]
                info!("Command: {} {}", cmd, args.join(" "));
                let mut command = std::process::Command::new(cmd);
                for arg in args {
                    command.arg(arg);
                }
                match command.spawn() {
                    #[cfg(feature = "trace_input")]
                    Ok(child) => {
                        info!("Command spawned with PID: {}", child.id());
                    }
                    Err(e) => {
                        error!(
                            "Failed to execute command '{} {}': {}",
                            cmd,
                            args.join(" "),
                            e
                        );
                    }
                    #[cfg(not(feature = "trace_input"))]
                    _ => {}
                }
            }
            KeyAction::Internal(func) => match func {
                FunctionEnum::SwitchWorkspace1 => {
                    self.set_keyboard_focus(None, serial);
                    self.workspace_manager.set_activated(WorkspaceId::new(1));
                }
                ...
            },
        }
    }
}
...
```



#pagebreak()



== DRM/KMS 裸机直连

项目在裸机终端中自行初始化 DRM/KMS 图形管线，并通过 GBM 和 EGL 建立 GPU 渲染上下文，使用 OpenGL ES 进行硬件加速合成显示。启动后该 Compositor 接管系统图形输出，并成为客户端程序（如终端模拟器、浏览器）的 Wayland 显示服务。

=== Linux 图形栈核心技术组件

#figure(
  image("introduce/opengl.png", width: 100%),
  caption: "opengl渲染过程演示图"
)

用画廊来举例，会比较容易理解。

画师就是 OpenGL/GLES，用于绘制用户提交的绘制需求，在绘制之前，画廊陈列员（EGL）
会负责与库存管理员（GBM）联系，确定好最终需要陈放画框的大小（buffer size），位置（egl buffer 映射）以及一些其他内容（egl context）。画师绘制完图画以后，先将图画堆积到队列中（queue frame），时机到达后（VBlank）就将原先墙上的画拿下，然后挂上新的画（page flip）。

下面是正式的介绍。

==== OpenGL/GLES

OpenGL（Open Graphics Library） 与其精简版 OpenGL ES（Embedded Systems） 是广泛使用的跨平台图形渲染 API，用于执行图形计算和渲染操作。在嵌入式或资源受限的环境中，OpenGL ES 更为常用，其接口更加轻量，适合直接在 TTY 裸机模式下运行。

在本项目中，OpenGL ES 被用于执行 GPU 加速的图形渲染任务。具体包括：

- 几何图形的绘制（如窗口、装饰、阴影）；
- 着色器程序的编译与执行；
- 将渲染内容输出到帧缓冲（Framebuffer）中，供后续显示。

在 TTY 裸机模式下，合成器通过 OpenGL ES 执行图形绘制操作，如几何图元绘制、纹理映射和着色器执行，最终将图像渲染到 GPU 管理的缓冲区（Framebuffer）中。

==== EGL

EGL 是连接 OpenGL ES 与本地窗口系统（如 X11、Wayland、或裸设备如 GBM）的中间接口库。其职责包括：

- 初始化图形上下文；
- 创建渲染表面（EGLSurface）；
- 在渲染器与底层硬件（GBM、DRM）之间建立连接；
- 管理 buffer swap（如 eglSwapBuffers()）与同步机制。

在 TTY 环境中，EGL 通常与 GBM 配合使用，将 GPU buffer 分配出来供 OpenGL ES 使用，建立渲染到显示设备之间的桥梁。

==== GBM（Generic Buffer Management）

GBM 是 Mesa 提供的一个用于和内核 DRM 系统交互的库，它的主要功能是：

- 分配可被 GPU 渲染的缓冲区（bo：buffer object）；
- 将这些缓冲区导出为 DMA-BUF handle，用于与 DRM 或其他进程共享；
- 为 EGL 提供可渲染的 EGLNativeWindowType。

GBM 允许在没有窗口系统的场景下（如 TTY 模式）创建 OpenGL 可用的 framebuffer，从而支持嵌入式系统和裸机合成器的图形输出。

==== Mesa3D

Mesa3D 是开源图形栈的核心，提供了 OpenGL、OpenGL ES、EGL、GBM 等多个图形接口的完整实现。它在用户空间运行，并与内核空间的 DRM 驱动协同工作。

Mesa 提供以下功能：

- 实现 OpenGL / GLES API，并将其转译为 GPU 硬件可识别的命令；
- 管理 shader 编译、状态机、纹理、缓冲区等所有渲染细节；
- 实现 GBM 与 DRM 的绑定，支持 buffer 分配与传输；
- 调度 page flip 请求，通过 DRM 与显示硬件同步。

==== DRM（Direct Rendering Manager）

*直接渲染管理器*（Direct Rendering Manager，缩写为 DRM）是 Linux 内核图形子系统的一部分，负责与 GPU（图形处理单元）通信。它允许用户空间程序（如图形服务器或 Wayland compositor）通过内核公开的接口，完成以下关键任务：

- 分配和管理图形缓冲区（buffer）
- 设置显示模式（分辨率、刷新率等）
- 与显示设备（显示器）建立连接
- 将 GPU 渲染结果显示到屏幕上 - PageFlip 页面翻转

DRM 是现代 Linux 图形栈的基础，允许程序绕过传统 X Server，直接操作 GPU，形成了“GPU 直连”的渲染路径。

#figure(
  image("introduce/DRM.png", width: 100%),
  caption: "DRM/KMS系统演示图"
)

要想理解 DRM ，首先要理解两个关键子模块的工作内容：

_*GEM（Graphic Execution Manager）*_

*图形执行管理器*（Graphics Execution Manager，简称 GEM）是 DRM 子系统中的另一个重要模块，主要用于内存管理，即如何分配和管理 GPU 可访问的图形缓冲区（buffer）。

它提供了如下功能：

- 为用户空间分配 GPU 使用的显存或系统内存缓冲区
- 提供缓冲区在用户空间与内核空间之间的共享与引用机制
- 管理缓冲区的生命周期和同步（避免读写冲突）

帧缓冲区对象（framebuffer）是帧内存对象的抽象，它提供了像素源给到 CRTC。帧缓冲区依赖于底层内存管理器分配内存。

在程序中，使用 DRM 接口创建 framebuffer、EGL 创建的渲染目标，底层通常都通过 GEM 管理。GEM 的存在使得多种图形 API（OpenGL ES、Vulkan、视频解码等）可以统一、高效地访问 GPU 资源。

_*KMS（Kernel Mode Setting）*_

*内核模式设置*（Kernel Mode Setting，简称 KMS）是 DRM 的子系统，用于控制显示设备的“输出路径”，即显示管线。它允许在内核空间完成分辨率设置、刷新率调整、帧缓冲切换等操作，而不依赖用户空间的图形服务器。

KMS 将整个显示控制器的显示 pipeline 抽象成以下几个部分：

- *Plane（图层）*
  
  每个 plane 表示一块可渲染的图像区域，可独立组合显示输出。plane 分为三类：
  
  - Primary：主图层，必需。对应于整个屏幕内容，通常显示整个帧缓冲区。
  - Cursor：用于显示鼠标光标，通常是一个小图层，支持硬件加速。
  - Overlay：可选的叠加图层，用于视频加速或硬件合成。

- *CRTC（Cathode Ray Tube Controller）*
  
  控制图像从 plane 传送到 encoder，类似一个“图像流控制器”，主要用于管理显示设备的扫描和刷新。一个 CRTC 通常绑定一个主 plane，但也可能支持多个 overlay。

- *Encoder（编码器）*
  
  将图像信号从 GPU 转换为特定格式，如 HDMI、DP、eDP、VGA 等。

- *Connector（连接器）*
  
  表示实际的物理接口（如 HDMI 接口、DisplayPort 接口），对应连接的显示设备（monitor）。

> 🔄 工作流程示意：*_Plane → CRTC → Encoder → Connector → Monitor_*

=== Wayland 通信流程与显示流程

本项目实现了一个独立于 X11、无需任何桌面环境即可运行的 Wayland 合成器（compositor），通过直接接管 TTY 并使用 DRM/KMS 完成图形显示。在显示系统的构建中，Wayland 扮演的是 图形系统通信协议 的角色，而具体的渲染、显示和输入处理由 DRM、GBM、EGL 与 libinput 等模块协同完成。

Wayland 合成器的主要职责是：

- 接受客户端（Wayland client）的连接与绘图请求
- 将客户端 buffer 进行合成、渲染并显示在屏幕上
- 处理来自内核的输入事件

#figure(
  image("introduce/wayland-drm.png", width: 70%),
  caption: "DRM/KMS系统演示图"
)


```
[Wayland Client]
    ↓ 提交 buffer（wl_buffer / linux-dmabuf）
[Compositor]
    ↓ OpenGL 合成（将多个窗口 buffer 组合）
[Framebuffer]
    ↓ DRM 显示 pipeline（crtc → encoder → connector）
[Monitor Output]
```


==== 客户端连接与交互

每个 Wayland 客户端通过 Socket 与合成器通信，注册所需协议（如 wl_surface, xdg_surface），并通过共享内存或 GPU buffer 提交其绘制内容。

==== Buffer 获取与提交

客户端通过 wl_buffer 协议提供绘制完成的内容。这个 buffer 可能来自：

- wl_shm：CPU 绘制后的共享内存（较慢）
- linux-dmabuf：GPU 渲染结果，零拷贝

==== 合成器接管 buffer 并合成

合成器在服务端接收 attach / commit 请求后，将客户端的 buffer 记录为当前帧的一部分。在下一帧刷新中，所有窗口的 buffer 会被 GPU 合成到一个输出 surface 上。

==== GPU 渲染与提交

使用 OpenGL ES 渲染这些 buffer（如绘制窗口、阴影、边框等），再通过 eglSwapBuffers 提交帧缓冲，交由 DRM 显示。

==== Page Flip 显示与 VBlank 同步

合成后的 framebuffer 通过 drmModePageFlip 提交，等待垂直同步（VBlank）时切换至新帧，防止 tearing。



=== 输入事件处理流程

==== libinput/evdev

evdev（Event Device） 是 Linux 内核提供的一个通用输入事件接口，所有输入设备（键盘、鼠标、触控板、游戏手柄等）在内核中都会以 /dev/input/eventX 设备节点的形式暴露，用户空间可以通过这些节点读取输入事件（如按键、移动、点击等）。

然而，直接与 evdev 接口打交道较为繁琐、底层，且各类设备的事件语义不尽相同。因此，在现代图形系统中，通常借助 libinput 作为更高级的输入事件处理库。

libinput 是一个*用户空间库*，提供统一的输入设备管理接口，具备以下功能：

- 统一处理来自 evdev 的事件流；
- 解析输入事件，生成高级抽象（如双指滚动、滑动、手势等）；
- 管理输入设备的生命周期（添加、移除）；
- 提供输入设备的识别信息（厂商、型号、功能等）；
- 与 Wayland compositor 无缝集成，支持多种后端（如 udev、seatd）。

输入事件首先由 Compositor 进行解析，无需响应时间时，发送给对应拥有 keyboard, pointer, touch focus 的客户端，通过协议如 wl_pointer.motion, wl_keyboard.key, wl_touch.down 等完成回传。


=== 代码实现细节

基本数据结构：

```rust
pub struct Tty {
    pub session: LibSeatSession,
    pub libinput: Libinput,
    pub gpu_manager: GpuManager<GbmGlesBackend<GlesRenderer, DrmDeviceFd>>,
    pub primary_node: DrmNode,
    pub primary_render_node: DrmNode,
    pub devices: HashMap<DrmNode, GpuDevice>,
    pub seat_name: String,
    pub dmabuf_global: Option<DmabufGlobal>,
}
pub struct GpuDevice {
    token: RegistrationToken,
    render_node: DrmNode,
    drm_scanner: DrmScanner,
    surfaces: HashMap<crtc::Handle, Surface>,
    #[allow(dead_code)]
    active_leases: Vec<DrmLease>,
    drm: DrmDevice,
    gbm: GbmDevice<DrmDeviceFd>,

    // record non_desktop connectors such as VR headsets
    // we need to handle them differently
    non_desktop_connectors: HashSet<(connector::Handle, crtc::Handle)>,
}

pub struct Surface {
    output: Output,
    #[allow(dead_code)]
    device_id: DrmNode,
    render_node: DrmNode,
    compositor: GbmDrmCompositor,
    dmabuf_feedback: Option<SurfaceDmabufFeedback>,
}

type GbmDrmCompositor = DrmCompositor<
    GbmAllocator<DrmDeviceFd>,
    GbmDevice<DrmDeviceFd>,
    Option<OutputPresentationFeedback>,
    DrmDeviceFd,
>;
```

这里主要维护三个数据结构，Tty 为总后端，其持有多个 OutputDevice，也就是 GPU 设备，每个 GPU 设备可能会持有多个 Surface，对应的是显示器。

Tty 中还获取记录主 GPU 节点与其渲染节点，输入设备管理器名称等

```rust
impl Tty {
    pub fn new(loop_handle: &LoopHandle<'_, GlobalData>) -> anyhow::Result<Self> {
        // Initialize session
        let (session, notifier) = LibSeatSession::new()?;
        let seat_name = session.seat();

        let mut libinput = Libinput::new_with_udev::<LibinputSessionInterface<LibSeatSession>>(
            session.clone().into(),
        );
        libinput.udev_assign_seat(&seat_name).unwrap();
        let libinput_backend = LibinputInputBackend::new(libinput.clone());

        loop_handle
            .insert_source(libinput_backend, |mut event, _, data| {
                if let InputEvent::DeviceAdded { device } = &mut event {
                    info!("libinput Device added: {:?}", device);
                    if device.has_capability(DeviceCapability::Keyboard) {
                        if let Some(led_state) = data
                            .input_manager
                            .get_keyboard()
                            .map(|keyboard| keyboard.led_state())
                        {
                            info!("Setting keyboard led state: {:?}", led_state);
                        }
                    }
                } else if let InputEvent::DeviceRemoved { ref device } = event {
                    info!("libinput Device removed: {:?}", device);
                }
                data.process_input_event(event);
            })
            .unwrap();

        loop_handle
            .insert_source(notifier, move |event, _, data| match event {
                SessionEvent::ActivateSession => {
                    info!("Session activated");
                    if data.backend.tty().libinput.resume().is_err() {
                        error!("error resuming libinput session");
                    };
                    for (node, device) in data
                        .backend
                        .tty()
                        .devices
                        .iter_mut()
                        .map(|(node, device)| (*node, device)) 
                    {
                        device.drm.activate(false).expect("failed to activate drm backend");
                        data.loop_handle.insert_idle(move |data| {

                            let device: &mut GpuDevice = if let Some(device) = data.backend.tty().devices.get_mut(&node) {
                                device
                            } else {
                                warn!("not change because of unknown device");
                                return;
                            };

                            let crtcs: Vec<_> = device.surfaces.keys().copied().collect();
                            for crtc in crtcs {
                                data.backend.tty().render_output(
                                    node,
                                    crtc,
                                    data.clock.now(),
                                    &mut data.render_manager,
                                    &data.output_manager,
                                    &data.workspace_manager,
                                    &mut data.cursor_manager,
                                    &data.input_manager,
                                    &data.clock,
                                    &data.loop_handle,
                                );
                            }
                        });
                    }
                }
                SessionEvent::PauseSession => {
                    info!("Session paused");
                    data.backend.tty().libinput.suspend();
                    for device in data.backend.tty().devices.values_mut() {
                        device.drm.pause();
                    }
                }
            })
            .unwrap();

        // Initialize Gpu manager
        let api = GbmGlesBackend::with_context_priority(ContextPriority::Medium);
        let gpu_manager = GpuManager::new(api).context("error creating the GPU manager")?;

        let primary_gpu_path = udev::primary_gpu(&seat_name)
            .context("error getting the primary GPU")?
            .context("couldn't find a GPU")?;

        info!("using as the primary node: {:?}", primary_gpu_path);

        let primary_node = DrmNode::from_path(primary_gpu_path)
            .context("error opening the primary GPU DRM node")?;

        info!("Primary GPU: {:?}", primary_node);

        // get render node if exit - /renderD128
        let primary_render_node = primary_node
            .node_with_type(NodeType::Render)
            .and_then(Result::ok)
            .unwrap_or_else(|| {
                warn!("error getting the render node for the primary GPU; proceeding anyway");
                primary_node
            });

        let primary_render_node_path = if let Some(path) = primary_render_node.dev_path() {
            format!("{:?}", path)
        } else {
            format!("{}", primary_render_node)
        };
        info!("using as the render node: {}", primary_render_node_path);

        Ok(Self {
            session,
            libinput,
            gpu_manager,
            primary_node,
            primary_render_node,
            devices: HashMap::new(),
            seat_name,
            dmabuf_global: None,
        })
    }
}
```

`Tty::new()` 主要做了以下几件事：

- 监听 libinput 输入事件
- 监听 session 事件
- 初始化 gbm，获取主 GPU 信息


```rs
    pub fn init(
        &mut self,
        loop_handle: &LoopHandle<'_, GlobalData>,
        display_handle: &DisplayHandle,
        output_manager: &mut OutputManager,
        render_manager: &RenderManager,
        state: &mut State,
    ) {
        let udev_backend = UdevBackend::new(&self.seat_name).unwrap();

        // gpu device
        for (device_id, path) in udev_backend.device_list() {
            if let Ok(node) = DrmNode::from_dev_id(device_id) {
                if let Err(err) = self.device_added(
                    node,
                    &path,
                    output_manager,
                    loop_handle,
                    display_handle,
                ) {
                    warn!("erro adding device: {:?}", err);
                }
            }
        }
        let mut renderer = self
            .gpu_manager
            .single_renderer(&self.primary_render_node)
            .unwrap();

        // initial shader
        render_manager.compile_shaders(&mut renderer.as_gles_renderer());
    
        state.shm_state.update_formats(renderer.shm_formats());

        match renderer.bind_wl_display(display_handle) {
            Ok(_) => info!("EGL hardware-acceleration enabled"),
            Err(err) => info!(?err, "Failed to initialize EGL hardware-acceleration"),
        }

        // create dmabuf
        let dmabuf_formats = renderer.dmabuf_formats();
        let default_feedback =
            DmabufFeedbackBuilder::new(self.primary_render_node.dev_id(), dmabuf_formats.clone())
                .build()
                .expect("Failed building default dmabuf feedback");
    
        let dmabuf_global = state
            .dmabuf_state
            .create_global_with_default_feedback::<GlobalData>(
                display_handle,
                &default_feedback,
            );
        self.dmabuf_global = Some(dmabuf_global);
    
        // Update the dmabuf feedbacks for all surfaces
        for device in self.devices.values_mut() {
            for surface in device.surfaces.values_mut() {
                surface.dmabuf_feedback = surface_dmabuf_feedback(
                    surface.compositor.surface(), 
                    &self.primary_render_node, 
                    &surface.render_node, 
                    &mut self.gpu_manager
                )
            }
        }

        // Expose syncobj protocol if supported by primary GPU
        if let Some(device) = self.devices.get(&self.primary_node) {
            let import_device = device.drm.device_fd().clone();
            if supports_syncobj_eventfd(&import_device) {
                info!("syncobj enabled");
                let syncobj_state =
                    DrmSyncobjState::new::<GlobalData>(&display_handle, import_device);
                state.syncobj_state = Some(syncobj_state);
            }
        }

        loop_handle
            .insert_source(udev_backend, move |event, _, data| match event {
                UdevEvent::Added { device_id, path } => {
                    if let Ok(node) = DrmNode::from_dev_id(device_id) {
                        if let Err(err) = data.backend.tty().device_added(
                            node,
                            &path,
                            &mut data.output_manager,
                            &data.loop_handle,
                            &data.display_handle,
                        ) {
                            warn!("erro adding device: {:?}", err);
                        }
                    }
                }
                UdevEvent::Changed { device_id } => {
                    if let Ok(node) = DrmNode::from_dev_id(device_id) {
                        data.backend.tty().device_changed(
                            node,
                            &mut data.output_manager,
                            &data.display_handle,
                            &data.loop_handle
                        )
                    }
                }
                UdevEvent::Removed { device_id } => {
                    if let Ok(node) = DrmNode::from_dev_id(device_id) {
                        data.backend.tty().device_removed(
                            &data.loop_handle,
                            &data.display_handle,
                            node,
                            &mut data.output_manager,
                            &mut data.state,
                        );
                    }
                }
            })
            .unwrap();
    }
```

`Tty::init()` 主要完成以下几件事：

- 监听 udev，获取所有 GPU 设备以及其对应的显示器信息
- 按照给定帧率执行渲染流程

本项目目前只实现了单 GPU 单显示器固定帧率渲染，渲染部分主要按照此流程重复执行：

```
render_output() // 渲染合成指定显示器上的内容
↓
queue_frame() // 将渲染好的内容送至等待队列，等待 pageflip
↓
VBlank // 垂直同步信号
↓
frame_submmit() // 提交帧，执行 pageflip
↓
flush_client() // 通知客户端渲染下一帧
```

#pagebreak()

== 平铺式布局算法设计

在一个窗口管理器中，布局系统扮演着核心角色。为了高效管理窗口的空间排布，本项目采用了一种结构清晰、修改高效的 *容器式二叉树（Contain Binary Tree）* 结构作为窗口布局的基础数据模型。该树结构基于 `SlotMap` 构建，结合唯一键值索引（Key-based access），理论上可以将常规操作如插入、删除、定位的时间复杂度优化至常数级别 `O(1)`。

=== 平铺树与浮动窗口

在窗口管理中，“浮动”与“平铺”是两种截然不同的布局策略。

对于浮动窗口来说，每个窗口都可以自由移动和调整大小，位置与层级由用户直接控制。由于它们彼此之间不存在位置上的约束与影响，因此在布局结构上无需记录窗口之间的相对关系。这类窗口更像是“独立漂浮”的实体，适合用于临时对话框、悬浮工具栏等场景。

相比之下，平铺窗口则要求每个窗口在屏幕空间中占据明确的非重叠区域。窗口的插入、删除与移动都会影响到其他窗口的位置或大小。因此，如何有效地记录和管理窗口之间的关系，成为平铺布局系统设计的核心问题。

本项目采用二叉树（Binary Tree）作为核心数据结构：

- 每个叶节点表示一个窗口，内部节点则表示一个分割操作（水平或垂直）。
- 当插入一个新窗口时，只需将目标节点转换为一个新的内部节点，并将其两个子节点分别指向原窗口和新窗口。
- 插入时自动按比例分配空间（如均分），形成结构性对等的子窗口布局。
- 删除窗口时只需将其父节点的另一个子节点提升替代，即可实现布局的自动“复原”，并保持一致的空间占用逻辑。

这种结构的优点在于：

- 局部性强：每次操作只影响相邻节点，避免全局调整；
- 操作直观：插入/删除窗口逻辑与视觉反馈一致，符合用户直觉；
- 便于导航与重排：通过遍历或修改节点，可以轻松实现焦点移动、窗口交换、尺寸调整等高级操作；
- 支持持久化与序列化：树结构便于保存当前布局状态，支持布局快照与恢复。

=== 数据结构优化

在平铺式窗口管理中，窗口之间的空间分配关系是紧密关联的。对任意一个窗口进行移动、调整大小、关闭等操作，往往会影响到其相邻窗口的布局结构。
因此，如何快速定位相关窗口并进行相应调整，成为决定系统响应效率的关键。

传统以二叉树为基础的实现方式，虽然结构简洁，但在实际操作中常常需要频繁遍历树结构以查找父节点、兄弟节点或子节点。这在窗口数量较多、布局嵌套较深时，会导致性能瓶颈。

为此，本项目对数据结构进行了有针对性的优化：

- 引入 slotmap（由 slotmap crate 提供的稀疏存储结构），作为节点存储容器，使每个窗口节点可以用稳定的键（Key）进行引用，避免因插入或删除节点而产生的结构失效问题。

- 每个节点中直接维护了与之关联的几个关键字段：
    - parent：指向其父节点
    - sibling：标记兄弟节点

#figure(
  image("introduce/slotmap.png", width: 60%),
  caption: "Slotmap"
)

通过这些显式的指针式引用关系，窗口之间的逻辑依赖不再依赖结构遍历获取，从而实现：

- O(1) 时间复杂度的节点访问与修改
- 更高效的窗口插入、删除与重排
- 无需递归或回溯查找节点关系

这种结构有效避免了传统树结构中“查找成本高、修改牵一发而动全身”的问题，显著提升了窗口管理操作的实时性和系统的整体响应速度。


```rs
use std::time::Duration;

use indexmap::IndexMap;
use slotmap::{new_key_type, SlotMap};
use smithay::{desktop::Window, utils::{Logical, Rectangle}};

use crate::{
    layout::Direction, 
    manager::{
        animation::{
            AnimationManager, AnimationType
        }, 
        window::WindowExt
    }
};

new_key_type! {
    pub struct NodeId;
}

#[derive(Debug, Clone)]
pub enum NodeData {
    Node {
        window: Window,

        sibling: NodeId,
        parent: NodeId,
    },
    Container {
        elements: Vec<NodeId>,
        rect: Rectangle<i32, Logical>,
        offset: i32,

        sibling: NodeId,
        parent: NodeId,

        direction: Direction,
    },
}


#[derive(Debug)]
pub struct TiledTree {
    nodes: SlotMap<NodeId, NodeData>,
    root: NodeId,

    windows: IndexMap<Window, NodeId>,

    gap: i32
}
```

=== 动态平铺

传统的平铺式窗口管理器通常采用固定策略（如始终在右侧或下方）来插入新窗口，这种行为简单但不够灵活，容易与用户操作意图脱节。

本项目引入了动态平铺机制，使得新建窗口的位置可以根据当前鼠标指针所在的窗口区域动态决定插入方式，从而增强窗口管理的直觉性与交互反馈。

- 当用户打开一个新窗口时，系统会检测当前鼠标所在的活跃窗口或焦点区域；
- 根据鼠标的位置判断是插入为上方、下方、左侧还是右侧子窗口；
- 原有窗口区域将被自动分割，新窗口与原窗口共享该区域并重新布局；
- 插入后焦点自动切换至新窗口，保持操作的连贯性。

#figure(
  image("introduce/focus.png", width: 60%),
  caption: "动态平铺示意图"
)

动态平铺的优势：
- 符合用户操作直觉：用户在哪个窗口区域执行操作，新窗口就出现在哪里，无需额外手动调整；
- 提高窗口组织效率：避免窗口总是堆叠到同一方向，造成空间浪费；
- 提升使用流畅性：使窗口布局更具上下文关联性，避免打断用户思路；

该机制不仅保留了平铺窗口自动布局的优势，也引入了一定程度的“空间感知”，增强了用户在窗口空间中的操控自由度，特别适合对窗口组织有较高要求的开发者与高效用户。


#pagebreak()

=== 平铺树插入算法

在动态平铺布局中，窗口的插入不仅需要考虑目标窗口的位置，还要明确插入的方向与插入策略，以决定新窗口在布局中的具体位置。

我们引入了 is_favour 字段来标记插入行为是否为优先插入。所谓“优先插入”，是指将新窗口插入到目标窗口的左侧或上方。这种插入方式会导致原有窗口的位置发生变化，特别是其左上角坐标（x, y）将被新窗口“向右或向下推移”。

相较之下，若新窗口插入在右侧或下方，则原窗口的位置保持不变，仅占用的空间被压缩，因此不需要额外处理其坐标。

为了保持布局一致性和视觉连贯性，对于“优先插入”的情况，系统需对原窗口的位置进行调整，以确保：

- 所有窗口在视觉上对齐，避免重叠或错位；
- 插入操作符合用户直觉，例如“向上插入”意味着新窗口在上方而旧窗口向下移动；
- 坐标系统在插入后保持一致，避免渲染异常；

插入时，获取被插入节点的信息，使用 split() 函数计算新窗口的大小（对半分），并且添加动画效果与向客户端确认 configure 等。

在这里操作的时间复杂度是 O(1)，但是由于树的修改与窗口大小的设置，会导致一定耗时。

```rs
pub fn insert(
    &mut self, 
    target: &Window, 
    direction: Direction, 
    window: Window, 
    is_favour: bool, 
    animation_manager: &mut AnimationManager
) -> bool {
    /*
        split new_rect from target nodes,
        convert target (nodes) into parent (container),
        insert new_target and old_target
    */

    let _span = tracy_client::span!("tiled tree: insert new window");

    if let Some(target_id) = self.find_node_id(target).cloned() {
        if let Some(NodeData::Node { window: old_window, sibling: old_sibling, parent: old_parent }) = self.nodes.get(target_id) {
            let old_window = old_window.clone();
            let old_sibling = old_sibling.clone();
            let old_parent = old_parent.clone();

            let old_rect = old_window.get_rect().unwrap();

            // get new rect
            let (target_rect, new_rect) = split_rect(old_rect, direction, 0, self.gap, is_favour);
            old_window.set_rect_cache(target_rect);
            window.set_rect_cache(new_rect);

            // insert target_copy and new nodes
            let target_copy_id = self.nodes.insert(
                NodeData::Node { 
                    window: old_window.clone(), 
                    sibling: NodeId::default(), 
                    parent: target_id
                }  
            );

            let new_id = self.nodes.insert(
                NodeData::Node { 
                    window: window.clone(), 
                    sibling: target_copy_id, 
                    parent: target_id 
                }
            );

            self.windows.insert(old_window.clone(), target_copy_id);
            self.windows.insert(window.clone(), new_id);

            if let Some(NodeData::Node { sibling, .. }) = self.nodes.get_mut(target_copy_id) {
                *sibling = new_id;
            }

            // convert target from node to container inplace
            let mut elements = vec![];

            if is_favour {
                elements.push(new_id);
                elements.push(target_copy_id);
            }else {
                elements.push(target_copy_id);
                elements.push(new_id);
            }

            if let Some(target_data) = self.nodes.get_mut(target_id) {
                *target_data = NodeData::Container { 
                    elements, 
                    rect: old_rect,
                    offset: 0,
                    sibling: old_sibling, 
                    parent: old_parent, 
                    direction 
                };
            }

            // add animation
            {
                // target node
                animation_manager.add_animation(
                    old_window,
                    old_rect,
                    target_rect,
                    Duration::from_millis(15),
                    AnimationType::EaseInOutQuad,
                );

                // new node
                let mut from = new_rect;
                if matches!(direction, Direction::Horizontal) {
                    if is_favour {
                        from.loc.x -= from.size.w;
                    } else {
                        from.loc.x += from.size.w;
                    }
                } else if matches!(direction, Direction::Vertical){
                    if is_favour {
                        from.loc.y -= from.size.h;
                    } else {
                        from.loc.y += from.size.h;
                    }
                }

                animation_manager.add_animation(
                    window,
                    from,
                    new_rect,
                    Duration::from_millis(45),
                    AnimationType::OvershootBounce,
                );
                
            }
        }
        return true;
    }

    false
}
```

在插入新窗口的时候，我们认为将 target 复制一份，原先的 target 转化类型为 Container 节点，复制的 target 与新窗口根据 is_favour 执行插入操作，这样的好处是，无需修改 target 节点以外的节点的信息，比如 target 的 sibling 的 sibling 信息，在代码层面上会更简洁。

对于第一个窗口的建立，此时没有任何的 target 节点，我们直接将其作为 root 节点，大小设置为 workspace 提供的 root_rect 大小，设置其 parent 与 sibling 都为自身。

```rs
pub fn new_with_first_node(window: Window, root_rect: Rectangle<i32, Logical>, gap: i32animation_manager: &mut AnimationManager) -> TiledTree {
    window.set_rect_cache(root_rect);
    window.send_rect(root_rect);

    let mut nodes = SlotMap::with_key();
    let mut windows = IndexMap::new();

    let first_node = NodeData::Node { 
        window: window.clone(), 
        sibling: NodeId::default(), 
        parent: NodeId::default()
    };

    let first_id = nodes.insert(first_node);
    windows.insert(window.clone(), first_id);

    // set sibling and parent to itself
    if let Some(NodeData::Node { sibling, parent, .. }) = nodes.get_mut(first_id) {
        *sibling = first_id;
        *parent = first_id;
    }

    // add animation
    let mut from = root_rect;
    from.loc.y += from.size.h;

    animation_manager.add_animation(
        window,
        from,
        root_rect,
        Duration::from_millis(30),
        AnimationType::EaseInOutQuad,
    );

    Self { 
        nodes, 
        root: first_id,

        windows,
        gap,
    }
}
```

=== 平铺树删除算法

由于我们使用的是二叉树，删除某个节点，只需要让 sibling 节点直接获取 container 节点存储的 rectangle 大小，并且将 container 节点转化为 sibling 对应的节点（sibling 可能是node，也可能是container）。这样无需修改无关节点的信息，实现高效简洁的操作。

```rs
pub fn remove(&mut self, target: &Window, animation_manager: &mut AnimationManager) {
    /*
        convert parent (Container) into sibling (Node),
        inherit parent's parent and sibling,
        use parent's rect,
        delete target and old_sibling node
    */

    let _span = tracy_client::span!("tiled tree: remove window");

    if let Some(target_id) = self.find_node_id(target).cloned() {
        if let Some(NodeData::Node { sibling: target_sibling, parent: target_parent, .. }) = self.nodes.get(target_id) {
            // only root node
            if target_id == self.root {
                self.nodes.remove(target_id);
                self.windows.shift_remove(target);

                return;
            }

            let target_parent = target_parent.clone();
            let target_sibling = target_sibling.clone();

            // convert parent into sibling node
            // use container's sibling & parent
            if let Some(sibling_data) = self.nodes.get(target_sibling) {
                match sibling_data {
                    NodeData::Node { window: sibling_window, .. } => {
                        let sibling_window = sibling_window.clone();

                        if let Some(NodeData::Container { rect: parent_rect, sibling: parent_sibling, parent: parent_parent, .. }) = self.nodes.get(target_parent) {
                            let sibling_window = sibling_window.clone();
                            let parent_rect = parent_rect.clone();

                            // merge target rect and sibling rect
                            let sibling_rect = sibling_window.get_rect().unwrap();
                            sibling_window.set_rect_cache(parent_rect.clone());

                            self.windows.insert(sibling_window.clone(), target_parent);
                            self.nodes[target_parent] = NodeData::Node {
                                window: sibling_window.clone(),
                                sibling: parent_sibling.clone(),
                                parent: parent_parent.clone(),
                            };

                            // add animation
                            animation_manager.add_animation(
                                sibling_window.clone(),
                                sibling_rect,
                                parent_rect,
                                Duration::from_millis(30),
                                AnimationType::EaseInOutQuad,
                            );
                        }

                        // remove old_sibling nodes
                        self.windows.insert(sibling_window.clone(), target_parent);
                    }
                    NodeData::Container { offset: sibling_offset, elements: sibling_elements, direction: sibling_direction, .. } => {
                        if let Some(NodeData::Container { rect: parent_rect, sibling: parent_sibling, parent: parent_parent, .. }) = self.nodes.get(target_parent) {
                            let sibling_elements = sibling_elements.clone();
                            let parent_rect = parent_rect.clone();
                            
                            self.nodes[target_parent] = NodeData::Container { 
                                elements: sibling_elements.clone(), 
                                rect: parent_rect.clone(), 
                                offset: sibling_offset.clone(),

                                sibling: parent_sibling.clone(), 
                                parent: parent_parent.clone(), 
                                direction: sibling_direction.clone()
                            };

                            self.update_rect_recursive(target_parent, parent_rect, animation_manager);

                            sibling_elements.iter().for_each(|node_id| {
                                if let Some(node_data) = self.nodes.get_mut(*node_id) {
                                    match node_data {
                                        NodeData::Node { parent, .. } => *parent = target_parent,
                                        NodeData::Container { parent, .. } => *parent = target_parent,
                                    }
                                }
                            });
                        }
                    }
                }
            }

            // remove from nodes and windows
            self.nodes.remove(target_id);
            self.nodes.remove(target_sibling);
            self.windows.shift_remove(target);
        }
    }
}
```

#pagebreak()

=== 平铺树更新算法

平铺树中，最复杂的就是更新算法，尤其是 resize 行为导致的更新。我们假设目前有这样的一个窗口布局：

#figure(
  image("introduce/resize.png", width: 80%),
  caption: "resize 操作"
)

左侧为当前屏幕中的窗口布局，右侧展示其对应的平铺树结构。在这种结构中，每一个容器节点（Container）代表一个空间划分操作，而叶子节点对应具体的窗口。

我们考虑如下场景：用户尝试对编号为 3 的窗口进行调整（resize），例如拖动其右边缘、上边缘或左边缘：
- 拖动 右侧边缘：只需与其右邻窗口（如窗口 4）联动更新；
- 拖动 上边缘：涉及与上方窗口（如窗口 2 和 4）共同调整；
- 拖动 左边缘：可能影响到整个左侧窗口组（窗口 1、2、3 等），更新范围较广。

上述情况表明，不同方向的拖动会引起不同粒度的区域更新，若逐一判断并精确维护每条边的依赖关系，将导致代码复杂度与维护成本大幅提升。

为简化更新逻辑，我们在平铺树的 Container 节点中引入了一个抽象属性：offset（偏移量）。该值用于记录从父节点到当前节点的矩形偏移，从而使得更新操作可以通过一次递归遍历统一下发到所有子节点，无需每次重新计算全局坐标。

具体而言：

- 当布局变更或触发重排时，调用 update_rect_recursive 函数；
- 每个 Container 节点根据其方向（水平或垂直）计算并更新其子节点的 rectangle 区域；
- 子节点递归调用自身的 update_rect_recursive 方法，传递并累加偏移值；
- 直至叶子节点，最终确定其在屏幕上的实际坐标与大小；

```rs
fn update_rect_recursive(&mut self, node_id: NodeId, new_rect: Rectangle<i32, Logical>, animation_manager: &mut AnimationManager) {
        let _span = tracy_client::span!("tiled tree: update_rect_recursive");

        if let Some(node_data) = self.nodes.get_mut(node_id) {
            match node_data {
                NodeData::Node { window, .. } => {
                    let old_rect = window.get_rect().unwrap();
                    window.set_rect_cache(new_rect);

                    // add animation
                    let window = window.clone();
                    animation_manager.add_animation(
                        window,
                        old_rect,
                        new_rect,
                        Duration::from_millis(30),
                        AnimationType::EaseInOutQuad,
                    );
                }

                NodeData::Container { elements, rect, offset, direction, .. } => {
                    *rect = new_rect;

                    let (rect_1, rect_2) = split_rect(new_rect, direction.clone(), offset.clone(), self.gap, false);
                    
                    let children = elements.clone();
                    for (child_id, sub_rect) in children.into_iter().zip([rect_1, rect_2]) {
                        self.update_rect_recursive(child_id, sub_rect, animation_manager);
                    }
                }
            }
        }
    }
```

接下来的问题就是如何找到最大的 Container 节点。

首先在设计数据结构的时候，我们有一个小巧思：

```rs
Container {
    elements: Vec<NodeId>,
    rect: Rectangle<i32, Logical>,
    offset: i32,

    sibling: NodeId,
    parent: NodeId,

    direction: Direction,
},
```

虽然二叉树只包含两个节点，但是我们使用 Vec[] 来存储子节点的值，这能够提供一个非常大的优势，具有了描述左右（上下）关系的能力。

在 Left 和 Right 的设计下，我们需要先判断这个节点是否是 Left 或者 Right，为其进行特殊的判断，代码层面上非常复杂。但是使用 Vec[] 有这样的好处：如果我们往右查询，则将 pos+1，检查是否有值。这样能够极大的简化代码复杂度，所有的节点都可以执行一致性操作。

有了这样的设计，在找寻 resize target 节点的时候会方便很多。

在原先的窗口布局假设上，我们考虑这个情况，水平移动，拖拽3号窗口的左边缘，应当修改全部的窗口。

直观的来说，我们直到 3号窗口的左侧是 1号窗口，他们的最大container 是 root 节点，所有直接修改 root 节点的 offset 再使用 update 函数遍历更新就可以实现 resize 操作。

所以 find_max_parent 的操作实际上就是：

1. 根据当前的 parent，判断 resize 操作的方向与 parent 的方向是否一致，如果一致则执行 2，如果不一致，则直接执行 3 
2. 根据 is_favour 判断 +1, -1（true则是左或者上），如果值存在，则将当前的 parent 作为 max parent，更新 offset 即可，若不存在，执行 3
3. 找到 parent 的 parent，将原 parent 作为节点，继续根据 is_favour 和 parent 的方向执行 2 操作，直到遇到 root 节点。

```rs
fn find_neighbor(&self, node_id: NodeId, direction: Direction, is_favour: bool) -> Option<(NodeId, NodeId)> {
    /*
        find node with direction and favour,
        if not, jump to parent and continue,
        if parent's direction is not eqult to given diretion,
        jump to parent's parent and continue,
        return current node id and resize target node id
    */
    let _span = tracy_client::span!("tiled tree: find_neighbor");

    if self.root == node_id {
        return None;
    }

    if let Some(node_data) = self.nodes.get(node_id) {
        let parent = match node_data {
            NodeData::Node { parent, .. } => {
                parent.clone()
            },
            NodeData::Container { parent, .. } => {
                parent.clone()
            }  
        };

        if let Some(NodeData::Container { elements, direction: parent_direction, .. }) = self.nodes.get(parent) {
            if direction == *parent_direction {
                if let Some(idx) = elements.iter().position(|id| *id == node_id) {
                    let neighbor = if is_favour {
                        idx.checked_sub(1).and_then(|i| elements.get(i))
                    } else {
                        elements.get(idx + 1)
                    };

                    if let Some(neighbor) = neighbor {
                        return Some((parent, neighbor.clone()));
                    }
                }
            }

            return self.find_neighbor(parent, direction, is_favour);
        }
    }

    return None;
}
```

至此，我们的 resize 函数就可以给出:

```rs
pub fn resize(&mut self, target: &Window, direction: Direction, offset: i32, is_favour: bool) {
    /*
        find the target nodes and resize target nodes,
        get the max container,
        resize the max container's elements
    */

    let _span = tracy_client::span!("tiled tree: resize window");

    if let Some(target_id) = self.find_node_id(target).cloned() {
        if self.root == target_id {
            return;
        }

        if let Some((max_parent_id, _)) = self.find_neighbor(target_id, direction, is_favour) {
            if let Some(NodeData::Container { rect, offset: parent_offset, .. }) = self.nodes.get_mut(max_parent_id) {
                let rect = rect.clone();
                // TODO: use client's given
                let min = 175;

                let half = match direction {
                    Direction::Horizontal => {
                        (rect.size.w - self.gap) / 2 - min
                    }
                    Direction::Vertical => {
                        (rect.size.h - self.gap) / 2 - min
                    }
                };
                *parent_offset = (*parent_offset + offset).clamp(-half, half);

                self.update_rect_recursive_without_animation(max_parent_id, rect);
            }
        }
    }
}
```

=== 平铺树窗口交换算法

在处理 resize 的时候，我们只需要考虑最大 parent 节点，然后遍历更新就可以了，在处理两个相邻窗口交换的问题上，会更复杂一些，我们必须找到 node 节点。

resize 的操作可以将 container 视为一个 node，进行整体的操作，而 exchange 操作则必须找到 node 节点，考虑以下的情况：

#figure(
  image("introduce/exchange.png", width: 80%),
  caption: "exchange 操作"
)

如果此时要让 3号和左侧窗口交换，显然应该与4号进行交换，根据 resize 的 find_neighbor() 函数，我们只能找到包含 1,4 的 contianer，因此还需要做以下的事情：

1. 如果 neighbor 的 direction 与移动的 direction 相同，说明此时只有一个窗口能够邻接，根据 is_favour 选择反向的即可（往左找则用右节点）
2. 如果 neighbor 的 direction 与移动的 direction 不同，说明此时是一个多窗口邻接的情况，为了符合交互直觉，我们认为：根据移动的窗口的原先 pos 来选择，如果原先在下方或者右方，那么就选择下方或者右方的窗口。

```rs
fn find_neighbor_only_node(&self, target_id: NodeId, direction: Direction, origin_idx: usize, is_favour: bool) -> Option<NodeId> {
    let _span = tracy_client::span!("tiled tree: find_neighbor_only_node");

    self.find_neighbor(target_id, direction, is_favour).and_then(|(_, neigbor_id)| {
        self.nodes.get(neigbor_id).and_then(|node_data| match node_data {
            NodeData::Node { .. } => {
                Some(neigbor_id)
            }
            NodeData::Container { .. } => {
                self.find_node_in_container(neigbor_id, direction,origin_idx, is_favour)
            }
        })
    })
}

fn find_node_in_container(&self, node_id: NodeId, direction: Direction, origin_idx: usize, is_favour: bool) -> Option<NodeId> {
    let _span = tracy_client::span!("tiled tree: find_node_in_container");

    if let Some(NodeData::Node { .. }) = self.nodes.get(node_id) {
        return Some(node_id);
    }

    else if let Some(NodeData::Container { elements, direction: container_direction, .. }) = self.nodes.get(node_id) {
        if &direction == container_direction {
            if is_favour {
                // invert because we need neighbor
                return self.find_node_in_container(elements[1], direction, origin_idx, is_favour);
            } else {
                return self.find_node_in_container(elements[0], direction, origin_idx, is_favour);
            }
        } else {
            return self.find_node_in_container(elements[origin_idx], direction, origin_idx, is_favour);
        }
    }

    None
}
```

之后处理 slotmap 与 windows 的存储内容

```rs
pub fn exchange(&mut self, target: &Window, direction: Direction, is_favour: bool, animation_manager: &mutAnimationManager) {
    /*
        find exchange node with vec add or sub,
        if none, get parent and continue until find root,
        exchange node
    */

    let _span = tracy_client::span!("tiled tree: exchange window");

    if let Some(target_id) = self.windows.get(target).cloned() {
        if self.root == target_id {
            return;
        }

        if let Some(NodeData::Node { window: target_window, parent, .. }) = self.nodes.get(target_id) {
            let target_window_copy = target_window.clone();
            let mut neighbor_window_copy = None;
            let mut origin_idx = 0;

            // get orifin idx
            if let Some(NodeData::Container { elements, .. }) = self.nodes.get(parent.clone()) {
                if let Some(idx) = elements.iter().position(|id| *id == target_id) {
                    origin_idx = idx;
                }
            }

            // find neighbor and exchange
            if let Some(neighbor_id) = self.find_neighbor_only_node(target_id, direction, origin_idx, is_favour) {
                if let Some(NodeData::Node { window: neighbor_window, .. }) = self.nodes.get_mut(neighbor_id) {
                    self.windows.insert(target_window_copy.clone(), neighbor_id);
                    self.windows.insert(neighbor_window.clone(), target_id);

                    neighbor_window_copy = Some(neighbor_window.clone());
                    *neighbor_window = target_window_copy.clone();
                }
            }

            // change target
            if let Some(neighbor_window_copy) = neighbor_window_copy {
                if let Some(NodeData::Node { window: target_window, .. }) = self.nodes.get_mut(target_id) {
                    *target_window = neighbor_window_copy.clone();
                }

                let target_rect = target_window_copy.get_rect().unwrap();
                let neighbor_rect = neighbor_window_copy.get_rect().unwrap();
                
                // exchange rect cache
                target_window_copy.set_rect_cache(neighbor_rect);
                neighbor_window_copy.set_rect_cache(target_rect);

                // add animation
                animation_manager.add_animation(
                    target_window_copy,
                    target_rect,
                    neighbor_rect,
                    Duration::from_millis(30),
                    AnimationType::EaseInOutQuad,
                );
                animation_manager.add_animation(
                    neighbor_window_copy,
                    neighbor_rect,
                    target_rect,
                    Duration::from_millis(30),
                    AnimationType::EaseInOutQuad,
                );
            }
        }
    }
}
```

=== expansion

Mondrian 还提供了一个类似全窗口看板的操作，将所有的平铺窗口与浮动窗口，设定为统一的大小，规整的排列在一起，方便用户进行窗口查询。

在计算行数的时候，我们使用了特殊的算法，确保了视觉上效果的和谐。

假设用户给定的设置是每行最多 4个窗口，如果此时有 5个窗口，此算法会产生 [3,2] 的布局而不是 [4,1]。

```rs
fn split_rows(total: usize, max_per_row: usize) -> Vec<usize> {
    let rows = (total + max_per_row - 1) / max_per_row;
    let base = total / rows;
    let mut remainder = total % rows;
    let mut result = Vec::new();

    for _ in 0..rows {
        if remainder > 0 {
            result.push(base + 1);
            remainder -= 1;
        } else {
            result.push(base);
        }
    }

    result
}
```

```rs
pub fn expansion(&self, animation_manager: &mut AnimationManager) {
    let _span = tracy_client::span!("container tree: expansion window");

    let total = self.windows().count();
    let max_per_row = 4;
    let gap = self.gap;
    let screen = self.root_rect;

    let row_counts = split_rows(total, max_per_row);
    
    #[cfg(feature = "trace_layout")]
    info!("expansion row counts: {:?}", row_counts);

    let row_count = row_counts.len();
    let win_height = (screen.size.h - gap * (row_count - 1) as i32) / row_count as i32;
    
    let total_gap = gap * (max_per_row + 1 - 1) as i32;
    let win_width = (screen.size.w - total_gap) / (max_per_row + 1) as i32;

    let mut window_iter = self.windows();

    let mut y = screen.loc.y;
    for &cols in &row_counts {
        let total_width = win_width * cols as i32 + total_gap;
        let start_x = screen.loc.x + (screen.size.w - total_width) / 2;

        for i in 0..cols {
            let x = start_x + i as i32 * (win_width + gap);
            let rect = Rectangle {loc: (x, y).into(), size: (win_width, win_height).into()};
            
            #[cfg(feature = "trace_layout")]
            info!("expansion rect: {:?}", rect);

            if let Some(window) = window_iter.next().cloned() {
                if window
                    .user_data()
                    .get::<ExpansionCache>()
                    .map(|guard| guard.0.borrow().is_none())
                    .unwrap_or(true) 
                {
                    let window_rect = window.get_rect().unwrap();

                    // ExpansionCache
                    let guard = window.user_data().get_or_insert::<ExpansionCache, _>(|| {
                        ExpansionCache(RefCell::new(Some(rect)))
                    });
                    *guard.0.borrow_mut() = Some(rect);

                    animation_manager.add_animation(
                        window,
                        window_rect,
                        rect,
                        Duration::from_millis(30),
                        AnimationType::EaseInOutQuad,
                    );
                }
            }
        }

        y += win_height + gap;
    }
}
```

=== invert

Mondrian 提供更改 Container direction 的操作，比如将水平分布的窗口转变为竖直分布。

只需要重新计算新窗口的大小并且通知 client 即可实现，我们使用 update 函数来统一处理。

```rs
pub fn invert(&mut self, target: &Window, animation_manager: &mut AnimationManager) {
    /*
        invert parent (Container) direction
        update recursive 
    */

    let _span = tracy_client::span!("tiled tree: invert window");

    if let Some(target_id) = self.find_node_id(target).cloned() {
        if let Some(NodeData::Node { parent: target_parent, .. }) = self.nodes.get(target_id) {
            let target_parent = target_parent.clone();

            if let Some(NodeData::Container { rect, direction, .. }) = self.nodes.get_mut(target_parent) {
                *direction = direction.invert();
                let rect = rect.clone();

                self.update_rect_recursive(target_parent, rect, animation_manager);
            }
        }
    }
}
```

=== float 与 tiled 切换

Mondrian 允许 float窗口与 tiled窗口共存与转换。

将 tiled窗口转化为 float非常简单，直接删除其在平铺树中的布局信息，将其弹出，设定大小为原布局的一定尺寸（或者向client发送事件，获取其推荐的大小），并且将鼠标的当前位置设定为整个窗口的中心。

将 float窗口转化为 tiled窗口则需要重新执行插入 map 逻辑，根据释放的位置，找到 target 窗口，执行 insert 操作。

```rs
pub fn switch_layout(&mut self, window: &Window, pointer_loc: Point<f64, Logical>) {
    self.workspace_manager.unmap_window(window, &mut self.animation_manager);

    match window.get_layout() {
        WindowLayout::Tiled => {
            // insert floating window
            self.window_manager.switch_layout(window);

            set_pointer_as_center(window, pointer_loc.to_i32_round(), &mut self.animation_manager);

            self.workspace_manager.map_window(None, window.clone(), ResizeEdge::TopLeft, &mut self.animation_manager);
        }
        WindowLayout::Floating => {
            // insert tiled window
            self.window_manager.switch_layout(window);

            if let Some(focus) = self.window_manager.window_under_tiled(pointer_loc, self.workspace_manager.current_workspace().id()) {
                let focus_rect = focus.get_rect().unwrap();

                let edge = detect_pointer_quadrant(pointer_loc, focus_rect.to_f64());
                self.workspace_manager.map_window(Some(&focus), window.clone(), edge, &mut self.animation_manager);
            } else {
                self.workspace_manager.map_window(
                    None,
                    window.clone(),
                    ResizeEdge::BottomRight,
                    &mut self.animation_manager,
                );
            }
        }
    }

}
```

#pagebreak()

== 动画效果实现

本吸纳纲目在保持“平铺核心逻辑简洁高效”的前提下，适度引入了 *过渡动画机制*，用于提升用户在窗口焦点切换、窗口布局变换、标签页切换等场景下的感知连贯性。动画不仅是美学设计的体现，更是信息传递与视觉引导的有效方式。

为了保证动画系统的性能和可控性，_Mondrian_ 采用了如下设计原则：

- *最小依赖*：动画系统直接构建在现有渲染框架之上，无引入额外 GUI 框架；
- *状态驱动*：所有动画过渡均由窗口状态变化触发，避免无效重绘；
- *可扩展性强*：动画接口设计后续可插拔，支持不同类型的动画模块（例如弹性缓动、贝塞尔插值等）。

为实现动画效果，*_Mondrian_ 并不直接修改窗口的最终状态数据*，而是采用一种 *“状态解耦、渲染驱动”* 的设计模式：

在触发需要动画的操作（如窗口移动、布局切换）时，实际的数据状态立即更新为目标值；  

然而，在渲染阶段，窗口的位置与属性并非立刻反映为最终状态，而是通过插值计算出一个*中间状态*，并随着时间推进逐帧更新，直到过渡完成。

这种做法带来两个显著优势：

1. *逻辑状态与渲染状态分离*：窗口管理逻辑保持简洁，不需要等待动画完成即可进行后续操作；
2. *动画过程可中断、可复用*：新的动画触发可以自然地替换旧的过渡轨迹，增强响应性与一致性。

例如，在窗口移动动画中，我们为每个窗口维护一个 `current_rect`（当前渲染位置）和 `target_rect`（逻辑目标位置），渲染时以时间为参数进行插值过渡，而不是一次性跳转。

=== Animation 结构体封装

为了实现动画效果，使用 `Animation` 结构体封装所需内容：

```rust
pub struct Animation {
    from: Rectangle<i32, Logical>,
    to: Rectangle<i32, Logical>,
    elapsed: Duration,
    duration: Duration,
    animation_type: AnimationType,
    pub state: AnimationState,
}

pub enum AnimationState {
    NotStarted,
    Running,
    Completed,
}

pub enum AnimationType {
    Linear,
    EaseInOutQuad,
    OvershootBounce,
}
```

=== Animation 功能实现

在动画未开始状态，触发 start() 函数，开始执行动画内容，并且在此会计算得到当前的插值内容，将大小信息 send 给窗口。

动画执行状态下，每次调用会触发 tick() 函数，代表往前执行一次。在这里需要判断动画时间是否到期，到期则标记结束状态，等待下一次被回收。

```rs
impl Animation {
    pub fn new(
        from: Rectangle<i32, Logical>,
        to: Rectangle<i32, Logical>,
        duration: Duration,
        animation_type: AnimationType,
    ) -> Self {
        Self {
            from,
            to,
            elapsed: Duration::ZERO,
            duration,
            animation_type,
            state: AnimationState::new(),
        }
    }

    pub fn start(&mut self) -> Rectangle<i32, Logical> {
        self.elapsed = Duration::ZERO;
        self.state = AnimationState::Running;
        self.from
    }

    pub fn tick(&mut self) {
        self.elapsed += Duration::from_millis(1);
        if self.elapsed >= self.duration {
            self.state = AnimationState::Completed;
        }
    }

    pub fn stop(&mut self) -> Rectangle<i32, Logical> {
        self.state = AnimationState::Completed;
        self.to
    }

    pub fn current_value(&self) -> Rectangle<i32, Logical> {
        let progress = (self.elapsed.as_secs_f64() / self.duration.as_secs_f64()).clamp(0.0, 1.0);
        process_rec(
            self.from,
            self.to,
            self.animation_type.get_progress(progress),
        )
    }
}
```

=== AnimationManager

所有 animation 由 AnimationManager 管理，统一发起动画，回收动画。在发起动画的时候，会判断当前此窗口是否已经存在了动画效果，存在则会强行终止到结束态，准备下一步动画，避免重复的 pending 导致信息错误与冲突。

```rs
pub struct AnimationManager {
    animations: HashMap<Window, Animation>,
}

impl AnimationManager {
    pub fn new() -> Self {
        Self { animations: HashMap::new() }
    }

    pub fn add_animation(
        &mut self,
        window: Window,
        from: Rectangle<i32, Logical>,
        to: Rectangle<i32, Logical>,
        duration: Duration,
        animation_type: AnimationType,
    ) {
        // void conflict
        self.stop_animation(&window);

        let animation = Animation::new(from, to, duration, animation_type);
        self.animations.insert(window, animation);
    }

    pub fn get_animation_data(&mut self, window: &Window) -> Option<Rectangle<i32, Logical>> {
        self.animations.get_mut(window).and_then(|animation| match animation.state {
            AnimationState::NotStarted => {
                let rect = animation.start();
                window.send_rect(rect);

                Some(rect)
            }
            AnimationState::Running => {
                animation.tick();
                let rect = animation.current_value();
                window.send_rect(rect);

                Some(rect)
            }
            _ => None,
        })
    }

    pub fn stop_animation(&mut self, window: &Window) {
        if let Some(animation) = self.animations.get_mut(window) {
            let rect = animation.stop();
            window.send_rect(rect);
        }
    }

    pub fn refresh(&mut self) {
        // clean dead animations
        self.animations
            .retain(|_, animation| !matches!(animation.state, AnimationState::Completed));
    }
}
```

=== 渲染请求

在窗口渲染阶段，系统首先判断该窗口是否处于动画过程中，即其 `AnimationState` 是否为 `Running`：

- 若动画已在进行中，则根据当前时间计算本帧对应的 *中间位置与尺寸*，用于绘制；
- 若动画尚未启动（`AnimationState == Pending`），则立即初始化动画状态，并将其标记为 `Running`，以便从下一帧开始正式执行过渡；
- 若动画已经完成，则会在 `refresh()` 函数下移出动画队列。
- 若动画未绑定动画对象，则直接使用窗口的最终几何状态进行渲染。

通过这种机制，Mondrian 能够在不影响窗口逻辑更新的前提下，实现 *按需触发、逐帧驱动* 的动画渲染流程，有效提升了动态响应的流畅性和可控性。

```rust
pub struct RenderManager {
    // no need now
    start_time: Instant,
}

...
    // windows
for window in windows {
        let rect = match animation_manager.get_animation_data(window) {
            Some(rect) => {
                rect
            }
            None => {
                if let Some(rect) = window
                    .user_data()
                    .get::<ExpansionCache>()
                    .and_then(|cache| cache.0.borrow().clone())
                    .or_else(|| window.get_rect())
                {
                    rect
                } else {
                    continue;
                }
            }
        };
        // windows border
        if let Some(focus) = &focus {
            if focus == window {
                elements.extend(self.get_border_render_elements(renderer, rect));
            }
        }
        
        let render_loc = (rect.loc - window.geometry().loc).to_physical_precise_round(output_scale);
        
        // set alpha
        let mut alpha  = 0.85;
        if let WindowLayout::Floating = window.get_layout() {
            alpha = 1.0
        } else if let Some(val) = window_manager.get_opacity(window) {
            alpha = val;
        }
        elements.extend(window
            .render_elements::<WaylandSurfaceRenderElement<R>>(
                renderer,
                render_loc,
                Scale::from(output_scale),
                alpha,
            ).into_iter().map(CustomRenderElements::Surface)
        );
    }
...

pub fn refresh(&mut self) {
    // clean dead animations
    AnimationManager
        .retain(|_, animation| !matches!(animation.state, AnimationState::Completed));
}
```


=== 实现案例

在触发 *窗口插入动画* 时，操作会涉及到平铺布局树（即二叉树结构）的结构调整。此过程中，我们能够获取：

- *被调整窗口* 的旧位置与新位置（`from → to`）

- *新插入窗口* 的初始几何信息（通常为最小化或透明状态）与目标位置

对于这些窗口，我们将其对应的几何变换信息封装为一个 `Animation` 对象，并统一加入到一个 *动画任务队列* 中，由事件循环（`eventloop`）逐帧驱动执行。

每一帧中，事件循环会对当前活跃的动画组执行插值更新，通过绘制中间状态实现平滑过渡，直到所有动画到达终点并完成移除。

这种方式实现了：

- 解耦逻辑结构修改与渲染过程

- 支持并发多个窗口动画协同

- 为后续扩展缓动函数、过渡风格等提供良好接口

```rust
...
// target node
animation_manager.add_animation(
    old_window,
    old_rect,
    target_rect,
    Duration::from_millis(15),
    AnimationType::EaseInOutQuad,
);

// new node
let mut from = new_rect;
if matches!(direction, Direction::Horizontal) {
    if is_favour {
        from.loc.x -= from.size.w;
    } else {
        from.loc.x += from.size.w;
    }
} else if matches!(direction, Direction::Vertical){
    if is_favour {
        from.loc.y -= from.size.h;
    } else {
        from.loc.y += from.size.h;
    }
}

animation_manager.add_animation(
    window,
    from,
    new_rect,
    Duration::from_millis(45),
    AnimationType::OvershootBounce,
);
...
```


#pagebreak()

== Configs manager

Mondrian 致力于打造一个极简而灵活的平铺式窗口管理器，核心理念是将窗口管理逻辑与用户界面完全解耦，将控制权交还给用户。

因此，项目不仅具备轻量的架构，还提供了丰富的个性化配置选项，以满足不同用户的使用习惯与美学偏好。

配置项计划预期涵盖：
- 自启动程序：用户可定义系统启动后自动运行的应用与服务，如网络管理器、输入法守护进程、壁纸设置等；
- 快捷键绑定：基于直观的数据结构实现键盘绑定逻辑，支持常见的窗口控制命令（如切换焦点、窗口移动、分屏操作、关闭等），也允许用户自由扩展；
- 窗口规则系统：为特定窗口设定行为规则，如指定浮动、默认尺寸、工作区绑定、焦点抢占策略等，实现窗口级的个性化控制；
- 布局默认配置：用户可以指定初始布局风格，决定窗口插入的默认策略（水平、垂直、动态等）；

配置文件均采用结构清晰、易编辑的格式，配合热重载机制，使得用户可以在不重启管理器的前提下即时生效更改，提升了开发效率与使用灵活度。

```sh
# █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█
# █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄

# --------------------------------------

monitor = 3440x1440@100


# █░░ ▄▀█ █░█ █▄░█ █▀▀ █░█
# █▄▄ █▀█ █▄█ █░▀█ █▄▄ █▀█

# --------------------------------------

exec-once = fcitx5 -d
exec-once = swww-daemon -f xrgb
exec-once = waybar -l off
# exec-once = kitty
```

*极简核心，生态协作*

Mondrian 遵循最小窗口管理器（Minimal Window Manager）的设计原则，不试图一体化实现桌面所有功能，而是专注于窗口管理本身。
为了实现完整的现代化桌面体验，用户可灵活选择与以下组件搭配使用：

- Rofi / wofi：程序启动器与切换器；
- Waybar：顶部状态栏与系统信息展示；
- mako / dunst：Wayland 下的通知系统；
- swww：动态壁纸支持；
- kitty：兼容终端模拟器；
- pipewire：音频控制；

Mondrian 提供了一份默认的美化模板，涵盖基本的主题配色、字体设置、透明度、圆角边框、Waybar 配置等，使用户开箱即用即可获得现代美观的桌面体验。
同时，用户也可以基于该模板进行深度自定义，例如修改主题色调、调整布局逻辑、替换系统组件，构建属于自己的独特桌面环境。

用户还可以实现编写 shell 脚本来绑定快捷键，实现更丰富的内容。

```sh
bind = Super_L+a, command, "sh ${MONDRIAN_SRC_PATH}/resource/rofilaunch.sh"

#!/usr/bin/env sh

# Rofi 样式编号，对应 style_*.rasi
rofiStyle="1"

# 字体大小（整数）
rofiScale="10"

# 窗口宽度 / 边框设置
width=2
border=4

# rofi 配置目录（根据实际路径修改）
confDir="${HOME}/.config"

# ===== 🗂️ 自动选择主题文件 =====

roconf="${confDir}/rofi/styles/style_${rofiStyle}.rasi"

# fallback: 如果指定样式不存在，就选第一个可用样式
if [ ! -f "${roconf}" ]; then
    roconf="$(find "${confDir}/rofi/styles" -type f -name "style_*.rasi" | sort -t '_' -k 2 -n | head -1)"
fi

# ===== 🧭 参数解析（运行模式） =====

case "${1}" in
    d|--drun) r_mode="drun" ;;
    w|--window) r_mode="window" ;;
    f|--filebrowser) r_mode="filebrowser" ;;
    h|--help)
        echo -e "$(basename "${0}") [action]"
        echo "d :  drun mode"
        echo "w :  window mode"
        echo "f :  filebrowser mode"
        exit 0
        ;;
    *) r_mode="drun" ;;
esac

# ===== 🎨 动态样式注入 =====

wind_border=$(( border * 3 ))
[ "${border}" -eq 0 ] && elem_border=10 || elem_border=$(( border * 2 ))

r_override="window {border: ${width}px; border-radius: ${wind_border}px;} element {border-radius: ${elem_border}px;}"
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"

# 获取当前 GNOME 图标主题（如果可用）
if command -v gsettings >/dev/null; then
    i_theme="$(gsettings get org.gnome.desktop.interface icon-theme | sed "s/'//g")"
    i_override="configuration {icon-theme: \"${i_theme}\";}"
else
    i_override=""
fi

# ===== 🚀 启动 rofi =====

rofi -show "${r_mode}" \
     -theme-str "${r_scale}" \
     -theme-str "${r_override}" \
     -theme-str "${i_override}" \
     -config "${roconf}"

```

#pagebreak()


== Layer-Shell 支持

为了实现桌面组件如状态栏、启动器、壁纸容器等持久性窗口，_Mondrian_ 支持 _*wlr-layer-shell*_ 协议。这一协议最初由 wlroots 提出，是实现 Wayland 桌面环境中“系统层级窗口”的标准手段。

#figure(
  image("introduce/layer_shell.png", width: 70%),
  caption: "layer_shell 协议示意图"
)

`layer-shell` 允许客户端以特定“图层”（layer）方式向合成器注册自身位置、对齐方式、屏幕边缘锚定，以及交互区域排除等属性，用于构建如：

- 层叠浮动窗口（layer: overlay）
- 顶部面板 / 状态栏（layer: top）
- 底部 dock / launcher（layer: bottom）
- 桌面壁纸容器（layer: background）

Mondrian 对该协议的支持不仅满足了桌面组件的功能需求，还为未来实现更多系统级 UI（如通知气泡、任务视图等）提供了良好的基础。

smithay 中对 `layer-shell` 协议有较好的支持，只需要引用并且构造所需内容即可。

```rust
use smithay::{
    delegate_layer_shell,
    desktop::{LayerSurface, WindowSurfaceType, layer_map_for_output},
    output::Output,
    reexports::wayland_server::protocol::wl_surface::WlSurface,
    wayland::{
        compositor::with_states,
        shell::wlr_layer::{LayerSurfaceData, WlrLayerShellHandler, WlrLayerShellState},
    },
};

use crate::state::GlobalData;

impl WlrLayerShellHandler for GlobalData {
    fn shell_state(&mut self) -> &mut WlrLayerShellState {
        &mut self.state.layer_shell_state
    }

    fn new_layer_surface(
        &mut self,
        surface: smithay::wayland::shell::wlr_layer::LayerSurface,
        wl_output: Option<smithay::reexports::wayland_server::protocol::wl_output::WlOutput>,
        _layer: smithay::wayland::shell::wlr_layer::Layer,
        namespace: String,
    ) {
        let output = if let Some(wl_output) = &wl_output {
            Output::from_resource(wl_output)
        } else {
            // TODO: output_manager -> Option<Output>
            Some(self.output_manager.current_output().clone())
        };

        let Some(output) = output else {
            warn!("no output for new layer surface, closing");
            surface.send_close();
            return;
        };

        let mut map = layer_map_for_output(&output);
        map.map_layer(&LayerSurface::new(surface, namespace))
            .unwrap();
    }

    fn layer_destroyed(&mut self, surface: smithay::wayland::shell::wlr_layer::LayerSurface) {
        // TODO: outputs
        let map = layer_map_for_output(self.output_manager.current_output());
        let layer = map
            .layers()
            .find(|&layer| layer.layer_surface() == &surface)
            .cloned();
        let (mut map, layer) = layer.map(|layer| (map, layer)).unwrap();
        map.unmap_layer(&layer);
    }

    fn new_popup(
        &mut self,
        _parent: smithay::wayland::shell::wlr_layer::LayerSurface,
        popup: smithay::wayland::shell::xdg::PopupSurface,
    ) {
        self.unconstrain_popup(&popup);
    }
}
delegate_layer_shell!(GlobalData);

impl GlobalData {
    pub fn layer_shell_handle_commit(&mut self, surface: &WlSurface) -> bool {
        let output = self.output_manager.current_output();

        let mut map = layer_map_for_output(output);

        if map
            .layer_for_surface(surface, WindowSurfaceType::TOPLEVEL)
            .is_some()
        {
            let initial_configure_sent = with_states(surface, |states| {
                states
                    .data_map
                    .get::<LayerSurfaceData>()
                    .unwrap()
                    .lock()
                    .unwrap()
                    .initial_configure_sent
            });

            map.arrange();
            if !initial_configure_sent {
                let layer = map
                    .layer_for_surface(surface, WindowSurfaceType::TOPLEVEL)
                    .unwrap();

                layer.layer_surface().send_configure();
            }

            return true;
        }

        false
    }
}
```

#pagebreak()

== XWayland 协议实现

在 Wayland 架构下，原生应用需通过 Wayland 协议与 Compositor 进行通信。但当前 Linux 桌面软件生态中，仍有大量基于 X11 的应用尚未迁移至 Wayland。为了兼容这些应用，XWayland 提供了一套桥接机制，使得 Wayland Compositor 能够托管 X11 应用窗口，从而保障传统应用的可用性。

XWayland 是一个运行在 Wayland 上的 X 服务器（Xwayland 进程），其核心作用是：

- 拦截所有 X11 应用的绘图请求；
- 将窗口绘制结果转交给 Wayland Compositor；
- 模拟必要的 X11 特性（窗口类型、输入事件等）以实现兼容性；
- 与 Wayland Compositor 通过特殊协议交互，例如 xwayland_surface_v1；

#figure(
  image("introduce/xwayland.png", width: 100%),
  caption: "Xwayland 通信实现"
)

在 Mondrian 中，已成功集成对 XWayland 的支持，流程如下：

- 自动启动 XWayland：Compositor 在启动时会监听相关环境并自动拉起 Xwayland 进程；
- Wayland 端监听 XWayland 连接请求，并通过 wlroots 或 Smithay 提供的接口（如 XWaylandSurface）管理其生命周期；
- 桥接输入与绘图事件：鼠标、键盘事件被准确转发给 X11 应用，绘图结果被嵌入 Wayland 的渲染流程；
- 统一窗口管理：XWayland 窗口被纳入与原生 Wayland 窗口一致的管理体系中（如平铺布局、快捷键切换等）；

*用户收益：*

- 无需额外配置即可运行大量现有 X11 应用（如 Firefox、GIMP、VS Code、Steam 等）；
- 兼容传统 GUI 工具链，用户可以继续使用熟悉的桌面软件；
- 窗口行为一致，X11 应用在 Compositor 中表现与原生窗口完全一致（可浮动、可平铺、可聚焦）；
- 加速用户迁移至 Wayland 环境，不牺牲现有生态；

*技术难点与解决方案：*

/ XWayland 启动时机:由 compositor 主动监听并拉起，保证连接时序正确
/ 输入事件的映射:与 Seat 统一处理，保持输入行为一致性
/ 窗口行为控制:提供 hooks 管理 XWayland surface 的生命周期与属性（例如 override_redirect）
/ 与原生窗口混合管理:所有窗口统一进入 layout 树，实现视觉一致性

```rust
impl XwmHandler for GlobalData {
    fn xwm_state(&mut self, _xwm: XwmId) -> &mut X11Wm {
        self.state.xwm.as_mut().unwrap()
    }

    fn new_window(&mut self, _xwm: XwmId, surface: X11Surface) {
        // judge layout
        // TODO: a wired bug, some client may start many no type windows
        // and the windows has no info, cannot judge layout
        let layout = if let Some(window_type) = surface.window_type() {
            match window_type {
                WmWindowType::Normal => {
                    if surface.is_popup() || surface.is_transient_for().is_some() {
                        WindowLayout::Floating
                    } else {
                        WindowLayout::Tiled
                    } 
                }
                _ => {
                    WindowLayout::Floating
                }
            }
        } else {
            WindowLayout::Floating
        };

        // create new window
        let window = Window::new_x11_window(surface);
        window.set_layout(layout);

        // add unmapped window in window_manager
        self.window_manager.add_window_unmapped(
            window.clone(),
            self.workspace_manager.current_workspace().id()
        );
    }

    fn new_override_redirect_window(&mut self, _xwm: XwmId, surface: X11Surface) {
        let layout = WindowLayout::Floating;

        // create new window
        let window = Window::new_x11_window(surface);
        window.set_layout(layout);

        // add unmapped window in window_manager
        self.window_manager.add_window_unmapped(
            window.clone(),
            self.workspace_manager.current_workspace().id()
        );
    }

    fn map_window_request(&mut self, _xwm: XwmId, surface: X11Surface) {
        surface.set_mapped(true).unwrap();

        if let Some(window) = self.window_manager.get_unmapped(&surface.into()).cloned() {
            self.set_mapped(&window);
            self.map_window(window);
        }
    }

    fn mapped_override_redirect_window(&mut self, _xwm: XwmId, _window: X11Surface) { }

    fn unmapped_window(&mut self, _xwm: XwmId, window: X11Surface) {
        if let Some(window) = self.window_manager.get_mapped(&window.into()) {
            self.unmap_window(&window.clone());
        }
    }

    fn destroyed_window(&mut self, _xwm: XwmId, window: X11Surface) {
        if let Some(window) = self.window_manager.get_mapped(&window.into()) {
            self.destroy_window(&window.clone());
        }
    }

    fn configure_request(
        &mut self,
        _xwm: XwmId,
        surface: X11Surface,
        x: Option<i32>,
        y: Option<i32>,
        w: Option<u32>,
        h: Option<u32>,
        _reorder: Option<Reorder>,
    ) {
        // we just set the new size, but don't let windows move themselves around freely
        if let Some(window) = self.window_manager.get_unmapped(&surface.clone().into()) {
            let mut rect = window.geometry();
            if let Some(x) = x {
                rect.loc.x = x;
            }
            if let Some(y) = y {
                rect.loc.y = y;
            }
            if let Some(w) = w {
                rect.size.w = w as i32;
            }
            if let Some(h) = h {
                rect.size.h = h as i32;
            }
            window.set_rect_cache(rect);
            window.send_rect(rect);
        } else if let Some(window) = self.window_manager.get_mapped(&surface.clone().into()) {
            match window.get_layout() {
                WindowLayout::Floating => {
                    let mut rect = window.geometry();
                    if let Some(x) = x {
                        rect.loc.x = x;
                    }
                    if let Some(y) = y {
                        rect.loc.y = y;
                    }
                    if let Some(w) = w {
                        rect.size.w = w as i32;
                    }
                    if let Some(h) = h {
                        rect.size.h = h as i32;
                    }
                    window.set_rect_cache(rect);
                    window.send_rect(rect);
                }
                WindowLayout::Tiled => {
                    let rect = window.get_rect();
                    let _ = surface.configure(rect);
                }
            }
        }
    }

    fn configure_notify(
        &mut self,
        _xwm: XwmId,
        _window: X11Surface,
        _geometry: Rectangle<i32, Logical>,
        _above: Option<x11rb::protocol::xproto::Window>,
    ) {
        // modify cache
        // info!("configure_notify");
    }

    fn fullscreen_request(&mut self, _xwm: XwmId, surface: X11Surface) {
        if let Some(window) = self.window_manager.get_mapped(&surface.clone().into()) {
            let output = self.output_manager.current_output();
            let output_rect = self.output_manager.output_geometry(output).unwrap();
            
            let _ = surface.configure(output_rect);
            
            surface.set_fullscreen(true).unwrap();
            self.fullscreen(window, output);
        }
    }

    fn unfullscreen_request(&mut self, _xwm: XwmId, surface: X11Surface) {
        if let Some(window) = self.window_manager.get_mapped(&surface.clone().into()) {
            surface.set_fullscreen(false).unwrap();

            if let Some(rect) = window.get_rect() {
                let _ = surface.configure(rect);
            }

            let output = self.output_manager.current_output().clone();
            self.unfullscreen(&output);
        }
    }

    fn resize_request(&mut self, _xwm: XwmId, window: X11Surface, _button: u32, _resize_edge: X11ResizeEdge) {
        if !self.input_manager.is_mainmod_pressed() {
            return
        }

        let pointer = match self.input_manager.get_pointer() {
            Some(pointer) => pointer,
            None => {
                warn!("Failed to get pointer");
                return
            }
        };
        
        let start_data = match pointer.grab_start_data() {
            Some(start_data) => start_data,
            None => {
                warn!("Failed to get start_data from: {:?}", pointer);
                return;
            }
        };

        self.resize_move_request(&PointerFocusTarget::X11Surface(window), &pointer, start_data, SERIAL_COUNTER.next_serial());
    }

    fn move_request(&mut self, _xwm: XwmId, window: X11Surface, _button: u32) {
        if !self.input_manager.is_mainmod_pressed() {
            return
        }

        let pointer = match self.input_manager.get_pointer() {
            Some(pointer) => pointer,
            None => {
                warn!("Failed to get pointer");
                return
            }
        };
        
        let start_data = match pointer.grab_start_data() {
            Some(start_data) => start_data,
            None => {
                warn!("Failed to get start_data from: {:?}", pointer);
                return;
            }
        };

        self.grab_move_request(&PointerFocusTarget::X11Surface(window), &pointer, start_data, SERIAL_COUNTER.next_serial());
    }
}
```



#pagebreak()


= 性能测试与分析

== HeapStrack 内存与 CPU 使用率分析

#figure(
  image("introduce/heapstrack1.png", width: 100%),
  caption: "heap strack cpu 与内存使用测试"
)

#figure(
  image("introduce/heapstrack2.png", width: 60%),
  caption: "heap strack cpu 与内存使用测试"
)

#figure(
  image("introduce/heapstrack3.png", width: 60%),
  caption: "heap strack cpu 与内存使用测试"
)

使用 heap strack 追踪本项目的运行，执行三分钟左右，最终得到 memory consumption 大约在 204.8kB，对于动辄上百MB的桌面环境来说，此内存使用量几乎可以忽略不计，并且在开始创建完成后能保持稳定（此时正执行视频播放与帧率测试）。

RSS 的使用量较大，推测是加载了 OpenGL、图形驱动、Wayland libs 等资源导致。

检查热力图发现，大部分的开销来自 client 与 compositor 的通信损耗，以及 compositor 进行事件处理的损耗。还有一部分则是来自 render manager 收集 wl_surface 导致的开销。

== Tracy profilter 跟踪分析 

tracy 可以用来方便的跟踪某个函数的生命周期与执行时间，在代码函数开头设置 span，等到函数结束退出，自动释放生命周期，这期间的信息会被 tracy 捕获。

#figure(
  image("introduce/tracy1.png", width: 100%),
  caption: "Tracy profilter 跟踪分析"
)

#figure(
  image("introduce/tracy2.png", width: 80%),
  caption: "Tracy profilter 跟踪分析"
)

在 Mondrian 中，耗时最大的操作是 render 与 tiled tree 的相关操作。

高刷显示器的普遍帧率在 120Hz 左右，因此每一帧的时间要在 8ms 左右，才能够有较好的体验。在本次跟踪分析中，我们一共打开了13个窗口，其中有 steam 游戏商城界面，firefox 视频播放，还有其他的 CLI 终端应用。平均的渲染操作时间在 792.23微秒，远远小于 8ms，因此能够做到稳定的高刷高帧率显示。

对于平铺树，我们已经使用了 HashMap 与 SlopMap 进行高度优化，实现了常数级别的操作，最复杂的 resize 操作，平均时间在 261 纳秒，insert 与 remove 操作涉及到树的更新与替换，时间损耗上反而比 resize 要高，但是平均只有 8.5 微秒与 2.17 微秒。可以说效果非常好。

#figure(
  image("introduce/tracy4.png", width: 100%),
  caption: "Tracy profilter 跟踪分析"
)

#figure(
  image("introduce/tracy5.png", width: 100%),
  caption: "Tracy profilter 跟踪分析"
)

在 tty 模式下，主要跟踪查看 Vblank 是否正常实现。可以看到，程序在接受到 vblank 通知后，才执行下一帧的渲染，然后将 frame callback 推送到 client 里去，这一步的逻辑是没有问题的。

在 tty 模式下，我们没有实现非常优秀的 GPU 渲染优化，比如 damage 区域的管理，scanout 的处理，但是平均时间来到了 1.44 ms，但这也是可以接受的，测试下来也是能够稳定显示显示器刷新率 - 100Hz

#figure(
  image("introduce/GPU.png", width: 100%),
  caption: "Tracy profilter 跟踪分析"
)

= 项目总结

本项目基于 Rust 语言与 Smithay 框架，自主实现了一个完整的 Wayland 合成器，具备显示服务器与窗口管理器的双重功能。通过底层 DRM/KMS 图形接口实现原生渲染管线，支持离屏绘制与缓冲区交换；在输入管理、窗口调度、协议兼容等方面构建了高度模块化的系统架构。

项目采用自定义的平铺式窗口管理算法，支持键盘驱动的高效交互模式，兼顾性能、美学与个性化配置；同时，已成功兼容多种 layer-shell 客户端，具备构建完整桌面环境的基础能力。

在保持稳定运行的基础上，本项目充分体现了现代合成器的核心特性——灵活、可拓展、安全、高效，为探索下一代 Linux 桌面提供了可行路径。后续将在多显示器支持、输入扩展、XWayland 兼容等方向持续推进，朝着高度可定制化与完整生态支持的目标不断完善。


#bibliography("ref.bib")

