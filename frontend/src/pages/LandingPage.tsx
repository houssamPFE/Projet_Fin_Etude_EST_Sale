
import { useEffect, useRef, useState } from "react"
import "./LandingPage.css"
import {
  ArrowRight,
  ArrowDown,
  Menu,
  X,
  Check,
  Star,
  ChevronDown,
  Sparkles,
  Shield,
  ShieldCheck,
  Zap,
  Mic,
  GraduationCap,
  Target,
  Globe2,
  Scale,
  Stethoscope,
  Briefcase,
  Clock,
  Send,
  Paperclip,
  Signal,
  Wifi,
  BatteryFull,
} from "lucide-react"

/* =========================================================
   NEXORA — Single-file landing page
   ========================================================= */

export default function NexoraLandingPage() {
  return (
    <main className="landing-page relative min-h-screen overflow-x-clip bg-[#020817] text-white">
      <BackgroundOrbs />
      <Navbar />
      <Hero />
      <TrustBar />
      <HowItWorks />
      <Features />
      <Domains />
      <LiveDemo />
      <Stats />
      <Testimonials />
      <Pricing />
      <FAQ />
      <FinalCTA />
      <Footer />
      <ScrollReveal />
    </main>
  )
}

/* ---------------------------------------------------------
   Background orbs + dot grid (fixed behind everything)
   --------------------------------------------------------- */
function BackgroundOrbs() {
  return (
    <div aria-hidden className="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
      <div className="absolute inset-0 nexora-dot-grid opacity-60" />
      <div
        className="nexora-orb absolute -top-40 -left-40 h-[500px] w-[500px] rounded-full blur-3xl"
        style={{ background: "#2563EB", ["--orb-opacity" as string]: "0.10" }}
      />
      <div
        className="nexora-orb absolute top-1/3 -right-40 h-[400px] w-[400px] rounded-full blur-3xl"
        style={{ background: "#7C3AED", ["--orb-opacity" as string]: "0.10", animationDelay: "1.5s" }}
      />
      <div
        className="nexora-orb absolute -bottom-40 left-1/3 h-[300px] w-[300px] rounded-full blur-3xl"
        style={{ background: "#2563EB", ["--orb-opacity" as string]: "0.05", animationDelay: "3s" }}
      />
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-[#020817]" />
    </div>
  )
}

/* ---------------------------------------------------------
   Brand logo (inline SVG so it sits natively on any bg)
   --------------------------------------------------------- */
function Logo({
  className = "",
  iconSize = 32,
  wordmarkClass = "text-xl",
}: {
  className?: string
  iconSize?: number
  wordmarkClass?: string
}) {
  return (
    <span className={`group inline-flex items-center gap-3 ${className}`}>
      <div className="relative">
        <div className="absolute inset-0 rounded-xl bg-gradient-to-br from-blue-500/20 to-purple-600/20 blur-lg opacity-0 transition-opacity duration-300 group-hover:opacity-100" />
        <img
          src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-26u9cky7itGCW6xGeluLsAKv9CKuAL.png"
          alt="NEXORA"
          className="relative h-14 w-auto rounded-lg transition-transform duration-300 group-hover:scale-[1.05]"
        />
      </div>
    </span>
  )
}

/* ---------------------------------------------------------
   Shared primitives
   --------------------------------------------------------- */
function GradientButton({
  children,
  href = "#",
  className = "",
  size = "md",
}: {
  children: React.ReactNode
  href?: string
  className?: string
  size?: "md" | "lg"
}) {
  const sizing = size === "lg" ? "px-7 py-3.5 text-base" : "px-5 py-2.5 text-sm"
  return (
    <a
      href={href}
      className={`nexora-shimmer-btn group relative inline-flex items-center gap-2 rounded-full font-semibold text-white transition-transform duration-300 hover:scale-[1.02] ${sizing} ${className}`}
      style={{
        background: "linear-gradient(135deg, #2563EB 0%, #7C3AED 100%)",
        boxShadow: "0 10px 30px -10px rgba(124,58,237,0.55), 0 0 0 1px rgba(255,255,255,0.06) inset",
      }}
    >
      <span className="relative z-10 inline-flex items-center gap-2">{children}</span>
    </a>
  )
}

function GhostButton({
  children,
  href = "#",
  className = "",
  size = "md",
}: {
  children: React.ReactNode
  href?: string
  className?: string
  size?: "md" | "lg"
}) {
  const sizing = size === "lg" ? "px-7 py-3.5 text-base" : "px-5 py-2.5 text-sm"
  return (
    <a
      href={href}
      className={`group inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.03] font-semibold text-white/90 backdrop-blur-md transition-all duration-300 hover:border-white/25 hover:bg-white/[0.06] hover:shadow-[0_0_30px_-8px_rgba(37,99,235,0.5)] ${sizing} ${className}`}
    >
      {children}
    </a>
  )
}

function GlassCard({
  children,
  className = "",
  glow = "blue",
}: {
  children: React.ReactNode
  className?: string
  glow?: "blue" | "purple" | "none" | string
}) {
  const glowColor =
    glow === "blue"
      ? "rgba(37,99,235,0.35)"
      : glow === "purple"
      ? "rgba(124,58,237,0.35)"
      : glow === "none"
      ? "transparent"
      : glow
  return (
    <div
      className={`group relative rounded-2xl border border-white/10 bg-white/[0.03] p-6 backdrop-blur-xl transition-all duration-500 hover:-translate-y-1.5 hover:border-white/20 ${className}`}
      style={
        {
          ["--glow" as string]: glowColor,
        } as React.CSSProperties
      }
    >
      <div
        className="pointer-events-none absolute inset-0 rounded-2xl opacity-0 transition-opacity duration-500 group-hover:opacity-100"
        style={{ boxShadow: `0 20px 60px -20px ${glowColor}, 0 0 0 1px rgba(255,255,255,0.04) inset` }}
      />
      <div className="relative z-10">{children}</div>
    </div>
  )
}

/* ---------------------------------------------------------
   1. Navbar
   --------------------------------------------------------- */
function Navbar() {
  const [scrolled, setScrolled] = useState(false)
  const [open, setOpen] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12)
    onScroll()
    window.addEventListener("scroll", onScroll, { passive: true })
    return () => window.removeEventListener("scroll", onScroll)
  }, [])

  const links = [
    { label: "Fonctionnalités", href: "#features" },
    { label: "Comment ça marche", href: "#how" },
    { label: "Experts", href: "#domains" },
    { label: "Tarifs", href: "#pricing" },
    { label: "FAQ", href: "#faq" },
  ]

  return (
    <header
      className={`fixed left-0 right-0 top-0 z-50 transition-all duration-500 ${
        scrolled
          ? "border-b border-white/10 bg-[#020817]/70 backdrop-blur-xl"
          : "border-b border-transparent bg-transparent"
      }`}
    >
      <nav className="mx-auto flex max-w-7xl items-center justify-between px-5 py-4 md:px-8">
        <a
          href="#"
          aria-label="NEXORA — Accueil"
          className="transition-transform duration-300 hover:scale-[1.02]"
        >
          <Logo iconSize={30} wordmarkClass="text-lg md:text-xl" />
        </a>

        <ul className="hidden items-center gap-8 lg:flex">
          {links.map((l) => (
            <li key={l.href}>
              <a
                href={l.href}
                className="text-sm text-white/60 transition-colors duration-300 hover:text-white"
              >
                {l.label}
              </a>
            </li>
          ))}
        </ul>

        <div className="hidden items-center gap-3 md:flex">
          <GhostButton href="/login">Se connecter</GhostButton>
          <GradientButton href="/register">
            Commencer gratuitement
            <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
          </GradientButton>
        </div>

        <button
          className="inline-flex h-10 w-10 items-center justify-center rounded-lg border border-white/10 bg-white/[0.03] text-white md:hidden"
          aria-label={open ? "Fermer le menu" : "Ouvrir le menu"}
          onClick={() => setOpen((v) => !v)}
        >
          {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
        </button>
      </nav>

      {/* Mobile menu */}
      <div
        className={`overflow-hidden border-t border-white/10 bg-[#020817]/95 backdrop-blur-xl transition-[max-height,opacity] duration-500 md:hidden ${
          open ? "max-h-[520px] opacity-100" : "max-h-0 opacity-0"
        }`}
      >
        <div className="mx-auto flex max-w-7xl flex-col gap-1 px-5 py-4">
          {links.map((l) => (
            <a
              key={l.href}
              href={l.href}
              onClick={() => setOpen(false)}
              className="rounded-lg px-3 py-3 text-sm text-white/80 transition-colors hover:bg-white/[0.04] hover:text-white"
            >
              {l.label}
            </a>
          ))}
          <div className="mt-3 flex flex-col gap-2">
            <GhostButton href="/login" className="justify-center">
              Se connecter
            </GhostButton>
            <GradientButton href="/register" className="justify-center">
              Commencer gratuitement
              <ArrowRight className="h-4 w-4" />
            </GradientButton>
          </div>
        </div>
      </div>
    </header>
  )
}

/* ---------------------------------------------------------
   2. Hero — asymmetric premium layout with floating iPhone
   --------------------------------------------------------- */
function Hero() {
  return (
    <section className="relative flex min-h-[100svh] items-center px-5 pt-28 pb-20 md:px-8 md:pt-32 md:pb-28 lg:pt-36">
      {/* Local atmospheric layers (on top of global orbs) */}
      <div aria-hidden className="pointer-events-none absolute inset-0 -z-10 overflow-hidden">
        {/* Aurora glow behind phone area */}
        <div
          className="absolute right-[-10%] top-[8%] h-[700px] w-[700px] rounded-full blur-[120px]"
          style={{
            background:
              "radial-gradient(closest-side, rgba(124,58,237,0.35), rgba(37,99,235,0.18) 55%, transparent 75%)",
          }}
        />
        {/* Soft left wash */}
        <div
          className="absolute left-[-8%] top-[30%] h-[500px] w-[500px] rounded-full blur-[120px]"
          style={{
            background:
              "radial-gradient(closest-side, rgba(37,99,235,0.25), transparent 70%)",
          }}
        />
        {/* Fine top grid fade */}
        <div
          className="absolute inset-x-0 top-0 h-[60%] opacity-[0.12]"
          style={{
            backgroundImage:
              "linear-gradient(to right, rgba(255,255,255,0.06) 1px, transparent 1px), linear-gradient(to bottom, rgba(255,255,255,0.06) 1px, transparent 1px)",
            backgroundSize: "56px 56px",
            maskImage:
              "radial-gradient(ellipse at 50% 0%, #000 0%, transparent 70%)",
            WebkitMaskImage:
              "radial-gradient(ellipse at 50% 0%, #000 0%, transparent 70%)",
          }}
        />
      </div>

      <div className="relative mx-auto grid w-full max-w-7xl grid-cols-1 items-center gap-16 lg:grid-cols-12 lg:gap-10">
        {/* ---------- Left column: copy + CTAs ---------- */}
        <div className="relative z-10 text-center lg:col-span-7 lg:text-left">
          {/* Badge */}
          <div className="nexora-float-slow mb-7 inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.04] px-4 py-1.5 text-xs font-medium text-white/80 backdrop-blur-md shadow-[0_0_40px_-10px_rgba(37,99,235,0.6)]">
            <span className="relative flex h-2 w-2">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-70" />
              <span className="relative inline-flex h-2 w-2 rounded-full bg-emerald-400" />
            </span>
            <Sparkles className="h-3.5 w-3.5 text-[#60a5fa]" />
            <span>Plateforme médicale certifiée</span>
            <span className="hidden text-white/20 sm:inline">·</span>
            <span className="hidden text-white/60 sm:inline">Médecins vérifiés</span>
          </div>

          {/* Heading */}
          <h1 className="text-pretty text-[2rem] font-bold leading-[1.1] tracking-[-0.025em] text-white sm:text-[2.5rem] md:text-[3rem] lg:text-[3.25rem] xl:text-[3.75rem]">
            L&apos;expertise médicale dont vous avez besoin,{" "}
            <span className="relative inline-block whitespace-nowrap">
              <span className="nexora-gradient-text italic font-extrabold">
                directement accessible
              </span>
              {/* Hand-drawn underline flourish */}
              <svg
                aria-hidden
                viewBox="0 0 300 14"
                preserveAspectRatio="none"
                className="absolute left-0 right-0 -bottom-1.5 h-2.5 w-full md:-bottom-2"
              >
                <defs>
                  <linearGradient id="hero-underline" x1="0" y1="0" x2="1" y2="0">
                    <stop offset="0%" stopColor="#60A5FA" />
                    <stop offset="50%" stopColor="#2563EB" />
                    <stop offset="100%" stopColor="#7C3AED" />
                  </linearGradient>
                </defs>
                <path
                  d="M3 9 Q 75 2, 150 7 T 297 6"
                  fill="none"
                  stroke="url(#hero-underline)"
                  strokeWidth="2.5"
                  strokeLinecap="round"
                />
              </svg>
              {/* Subtle sparkle */}
              <Sparkles
                aria-hidden
                className="absolute -right-4 -top-2 h-4 w-4 text-[#c084fc] opacity-80 md:-right-5 md:-top-3 md:h-5 md:w-5"
              />
            </span>
            <span className="text-white">.</span>
          </h1>

          {/* Subtitle */}
          <p className="mx-auto mt-6 max-w-md text-balance text-base leading-relaxed text-white/60 md:text-lg lg:mx-0">
            Consultez des <span className="text-white/90">médecins spécialistes</span> certifiés en quelques minutes.
          </p>

          {/* CTAs */}
          <div className="mt-9 flex flex-col items-center gap-3 sm:flex-row sm:justify-center lg:justify-start">
            <GradientButton href="/register" size="lg">
              Commencer gratuitement
              <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
            </GradientButton>
            <GhostButton href="#demo" size="lg">
              Voir la démo
              <ArrowDown className="h-4 w-4 transition-transform group-hover:translate-y-0.5" />
            </GhostButton>
          </div>

          {/* Micro-guarantees */}
          <div className="mt-4 flex flex-wrap items-center justify-center gap-x-4 gap-y-1 text-xs text-white/45 lg:justify-start">
            <span className="inline-flex items-center gap-1.5">
              <Check className="h-3.5 w-3.5 text-emerald-400" /> Consultations sécurisées
            </span>
            <span className="inline-flex items-center gap-1.5">
              <Check className="h-3.5 w-3.5 text-emerald-400" /> Médecins vérifiés
            </span>
            <span className="inline-flex items-center gap-1.5">
              <Check className="h-3.5 w-3.5 text-emerald-400" /> Disponible 24/7
            </span>
          </div>

          {/* Social proof row */}
          <div className="mt-9 flex flex-col items-center gap-4 sm:flex-row sm:gap-6 lg:items-center lg:justify-start">
            {/* Avatar stack */}
            <div className="flex -space-x-2">
              {[
                "from-[#2563EB] to-[#60a5fa]",
                "from-[#7C3AED] to-[#c084fc]",
                "from-[#0ea5e9] to-[#22d3ee]",
                "from-[#f59e0b] to-[#f97316]",
                "from-[#10b981] to-[#34d399]",
              ].map((grad, i) => (
                <span
                  key={i}
                  className={`inline-flex h-9 w-9 items-center justify-center rounded-full border-2 border-[#020817] bg-gradient-to-br ${grad} text-[11px] font-bold text-white shadow-lg`}
                >
                  {["A", "S", "Y", "L", "N"][i]}
                </span>
              ))}
              <span className="inline-flex h-9 w-9 items-center justify-center rounded-full border-2 border-[#020817] bg-white/10 text-[10px] font-semibold text-white/80 backdrop-blur">
                +2k
              </span>
            </div>
            <div className="flex flex-col items-center gap-1 sm:items-start">
              <span className="flex items-center gap-1 text-amber-400">
                {Array.from({ length: 5 }).map((_, i) => (
                  <Star key={i} className="h-4 w-4 fill-amber-400" />
                ))}
                <span className="ml-1 text-sm font-semibold text-white">4,9 / 5</span>
              </span>
              <span className="text-xs text-white/50">
                +500 médecins certifiés · +50 000 consultations réussies
              </span>
            </div>
          </div>
        </div>

        {/* ---------- Right column: floating iPhone ---------- */}
        <div className="relative lg:col-span-5">
          <PhoneMockup />
        </div>
      </div>
    </section>
  )
}

/* ---------------------------------------------------------
   Phone mockup — premium floating iPhone with NEXORA app
   --------------------------------------------------------- */
function PhoneMockup() {
  return (
    <div
      className="relative mx-auto w-full max-w-[340px] sm:max-w-[380px] lg:max-w-none"
      style={{ perspective: "1800px" }}
    >
      {/* Rotating conic ring behind */}
      <div
        aria-hidden
        className="pointer-events-none absolute left-1/2 top-1/2 -z-10 h-[120%] w-[120%] -translate-x-1/2 -translate-y-1/2 rounded-full opacity-40 blur-2xl nexora-spin-slow"
        style={{
          background:
            "conic-gradient(from 0deg, rgba(37,99,235,0.0), rgba(37,99,235,0.35), rgba(124,58,237,0.35), rgba(37,99,235,0.0))",
        }}
      />
      {/* Hot glow behind phone */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 -z-10 translate-y-8 rounded-[60px] blur-3xl"
        style={{
          background:
            "radial-gradient(closest-side, rgba(124,58,237,0.55), rgba(37,99,235,0.35) 50%, transparent 75%)",
          opacity: 0.55,
        }}
      />

      {/* 3D tilt wrapper */}
      <div
        className="relative mx-auto"
        style={{ transform: "rotateY(-10deg) rotateX(6deg) rotateZ(-1deg)" }}
      >
        {/* Float + shadow */}
        <div className="nexora-float relative mx-auto w-[290px] sm:w-[320px]">
          {/* Phone body */}
          <div
            className="relative rounded-[52px] border border-white/15 bg-gradient-to-b from-[#1c2434] via-[#0b1120] to-[#050914] p-[3px] shadow-[0_50px_120px_-30px_rgba(0,0,0,0.8),0_30px_80px_-25px_rgba(124,58,237,0.55),0_0_0_1px_rgba(255,255,255,0.05)_inset]"
          >
            {/* Outer bezel highlight */}
            <div className="pointer-events-none absolute inset-0 rounded-[52px] ring-1 ring-inset ring-white/10" />
            {/* Titanium side specular */}
            <div
              className="pointer-events-none absolute inset-y-10 -left-[2px] w-[3px] rounded-l-full"
              style={{
                background:
                  "linear-gradient(to bottom, transparent, rgba(255,255,255,0.25), transparent)",
              }}
            />
            <div
              className="pointer-events-none absolute inset-y-10 -right-[2px] w-[3px] rounded-r-full"
              style={{
                background:
                  "linear-gradient(to bottom, transparent, rgba(255,255,255,0.18), transparent)",
              }}
            />

            {/* Screen */}
            <div className="relative overflow-hidden rounded-[48px] bg-[#05060c]">
              {/* Wallpaper gradient */}
              <div
                aria-hidden
                className="absolute inset-0"
                style={{
                  background:
                    "radial-gradient(120% 80% at 20% 0%, rgba(37,99,235,0.22) 0%, transparent 55%), radial-gradient(100% 70% at 100% 100%, rgba(124,58,237,0.22) 0%, transparent 60%), linear-gradient(180deg, #0a1224 0%, #06091a 60%, #05060c 100%)",
                }}
              />

              {/* Status bar */}
              <div className="relative flex items-center justify-between px-7 pt-3 text-[11px] font-semibold text-white/90">
                <span>9:41</span>
                <div className="flex items-center gap-1.5">
                  <Signal className="h-3 w-3" />
                  <Wifi className="h-3 w-3" />
                  <BatteryFull className="h-3.5 w-3.5" />
                </div>
              </div>

              {/* Dynamic island */}
              <div className="relative mt-1 flex justify-center">
                <div className="h-[30px] w-[110px] rounded-full bg-black shadow-[0_0_0_1px_rgba(255,255,255,0.04)_inset]" />
              </div>

              {/* App content */}
              <div className="relative px-5 pb-4 pt-4">
                {/* App header */}
                <div className="flex items-center justify-between">
                  <Logo iconSize={22} wordmarkClass="text-[13px]" />
                  <div className="flex items-center gap-1.5">
                    <span className="inline-flex h-7 w-7 items-center justify-center rounded-full bg-white/[0.06] ring-1 ring-white/10">
                      <Globe2 className="h-3.5 w-3.5 text-white/70" />
                    </span>
                    <span className="inline-flex h-7 w-7 items-center justify-center rounded-full bg-gradient-to-br from-[#2563EB] to-[#7C3AED] text-[10px] font-bold text-white">
                      AK
                    </span>
                  </div>
                </div>

                {/* Greeting */}
                <div className="mt-5">
                  <p className="text-[11px] uppercase tracking-[0.18em] text-white/40">
                    Bonjour, Anas
                  </p>
                  <h3 className="mt-1 text-[18px] font-bold leading-tight text-white">
                    Quelle expertise{" "}
                    <span className="nexora-gradient-text">aujourd&apos;hui ?</span>
                  </h3>
                </div>

                {/* Quick domains */}
                <div className="mt-4 grid grid-cols-3 gap-2">
                  {[
                    { icon: Stethoscope, label: "Général", tint: "from-[#2563EB]/25 to-[#2563EB]/5", color: "text-[#60a5fa]" },
                    { icon: Shield, label: "Cardio", tint: "from-[#10b981]/25 to-[#10b981]/5", color: "text-emerald-300" },
                    { icon: Zap, label: "Dermato", tint: "from-[#7C3AED]/25 to-[#7C3AED]/5", color: "text-[#c084fc]" },
                  ].map(({ icon: Icon, label, tint, color }) => (
                    <div
                      key={label}
                      className={`flex flex-col items-center gap-1.5 rounded-2xl bg-gradient-to-b ${tint} p-2.5 ring-1 ring-white/10`}
                    >
                      <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-white/[0.06]">
                        <Icon className={`h-4 w-4 ${color}`} />
                      </span>
                      <span className="text-[10px] font-semibold text-white/80">{label}</span>
                    </div>
                  ))}
                </div>

                {/* Chat thread preview */}
                <div className="mt-4 space-y-2.5">
                  {/* User bubble */}
                  <div className="flex justify-end">
                    <div
                      className="max-w-[85%] rounded-2xl rounded-br-md px-3 py-2 text-[11px] leading-snug text-white shadow-lg"
                      style={{
                        background:
                          "linear-gradient(135deg, rgba(37,99,235,0.95) 0%, rgba(124,58,237,0.95) 100%)",
                      }}
                    >
                      J'ai des douleurs thoraciques depuis 2 jours. Que faire ?
                    </div>
                  </div>

                  {/* AI bubble */}
                  <div className="flex justify-start">
                    <div className="max-w-[90%] rounded-2xl rounded-bl-md border border-[#7C3AED]/40 bg-white/[0.04] px-3 py-2 text-[11px] leading-snug text-white/90 backdrop-blur-md shadow-[0_0_30px_-12px_rgba(124,58,237,0.7)]">
                      <div className="mb-1 flex items-center gap-1.5 text-[10px] font-bold text-[#c084fc]">
                        <Sparkles className="h-3 w-3" />
                        NEXORA IA
                        <span className="ml-auto inline-flex items-center gap-0.5 text-emerald-400">
                          <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
                          94%
                        </span>
                      </div>
                      <p>
                        Consultez un cardiologue en urgence. En attendant : repos, évitez
                        l'effort physique. Si la douleur s'intensifie, appelez le 15.
                      </p>
                      {/* typing dots */}
                      <div className="mt-1.5 flex items-center gap-1">
                        <span className="nexora-bounce-dot h-1 w-1 rounded-full bg-[#c084fc]" style={{ animationDelay: "0s" }} />
                        <span className="nexora-bounce-dot h-1 w-1 rounded-full bg-[#c084fc]" style={{ animationDelay: "0.15s" }} />
                        <span className="nexora-bounce-dot h-1 w-1 rounded-full bg-[#c084fc]" style={{ animationDelay: "0.3s" }} />
                      </div>
                    </div>
                  </div>
                </div>

                {/* Input bar */}
                <div className="mt-4 flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.04] px-3 py-2 backdrop-blur-md">
                  <Paperclip className="h-3.5 w-3.5 text-white/50" />
                  <span className="flex-1 text-[11px] text-white/45">
                    Posez une question…
                    <span className="nexora-blink ml-0.5 inline-block h-3 w-[1px] align-middle bg-white/60" />
                  </span>
                  <Mic className="h-3.5 w-3.5 text-white/60" />
                  <span className="flex h-6 w-6 items-center justify-center rounded-full bg-gradient-to-br from-[#2563EB] to-[#7C3AED]">
                    <Send className="h-3 w-3 text-white" />
                  </span>
                </div>

                {/* Home indicator */}
                <div className="mt-4 flex justify-center">
                  <span className="h-1 w-24 rounded-full bg-white/40" />
                </div>
              </div>

              {/* Screen reflection */}
              <div
                aria-hidden
                className="pointer-events-none absolute inset-0"
                style={{
                  background:
                    "linear-gradient(160deg, rgba(255,255,255,0.10) 0%, rgba(255,255,255,0) 25%, rgba(255,255,255,0) 75%, rgba(255,255,255,0.04) 100%)",
                }}
              />
            </div>
          </div>
        </div>

        {/* Ground reflection / shadow */}
        <div
          aria-hidden
          className="pointer-events-none absolute left-1/2 top-full mt-4 h-10 w-[60%] -translate-x-1/2 rounded-[50%] blur-xl"
          style={{
            background:
              "radial-gradient(closest-side, rgba(0,0,0,0.75), transparent 70%)",
          }}
        />
      </div>

      {/* Floating chips around the phone */}
      <FloatingChip
        className="left-[-6%] top-[12%] hidden sm:flex"
        icon={<Zap className="h-3.5 w-3.5 text-[#60a5fa]" />}
        title="Réponse IA"
        sub="2,8 s"
        delay="0.4s"
      />
      <FloatingChip
        className="right-[-6%] top-[6%] hidden sm:flex"
        icon={<ShieldCheck className="h-3.5 w-3.5 text-emerald-400" />}
        title="Expert certifié"
        sub="Dr. Amrani · Cardio"
        delay="0.9s"
      />
      <FloatingChip
        className="right-[-10%] top-[48%] hidden sm:flex"
        icon={<Sparkles className="h-3.5 w-3.5 text-[#c084fc]" />}
        title="Confiance IA"
        sub="94%"
        delay="1.4s"
        highlight
      />
      <FloatingChip
        className="left-[-10%] bottom-[12%] hidden sm:flex"
        icon={<Clock className="h-3.5 w-3.5 text-[#60a5fa]" />}
        title="Dispo 24/7"
        sub="Temps réel"
        delay="1.9s"
      />
    </div>
  )
}

function FloatingChip({
  className = "",
  icon,
  title,
  sub,
  delay = "0s",
  highlight = false,
}: {
  className?: string
  icon: React.ReactNode
  title: string
  sub: string
  delay?: string
  highlight?: boolean
}) {
  return (
    <div
      className={`nexora-float-slow absolute z-20 flex items-center gap-2 rounded-2xl border border-white/10 bg-white/[0.06] px-3 py-2 text-left backdrop-blur-xl ${
        highlight
          ? "shadow-[0_20px_60px_-20px_rgba(124,58,237,0.7)]"
          : "shadow-[0_20px_50px_-20px_rgba(0,0,0,0.7)]"
      } ${className}`}
      style={{ animationDelay: delay }}
    >
      {highlight && (
        <span
          aria-hidden
          className="absolute inset-0 rounded-2xl opacity-60"
          style={{
            background:
              "linear-gradient(135deg, rgba(37,99,235,0.25), rgba(124,58,237,0.25))",
          }}
        />
      )}
      <span className="relative flex h-7 w-7 items-center justify-center rounded-lg bg-white/[0.06] ring-1 ring-white/10">
        {icon}
      </span>
      <span className="relative flex flex-col leading-tight">
        <span className="text-[10px] uppercase tracking-[0.14em] text-white/50">{title}</span>
        <span className="text-xs font-semibold text-white">{sub}</span>
      </span>
    </div>
  )
}

/* ---------------------------------------------------------
   3. Trust Bar (marquee)
   --------------------------------------------------------- */
function TrustBar() {
  const logos = [
    "CHU Casablanca",
    "Clinique Agdal",
    "Hôpital Cheikh Zaid",
    "Centre Médical Maarif",
    "Polyclinique Atlas",
    "Labo BioMaroc",
    "Pharmacie Centrale",
  ]
  const loop = [...logos, ...logos]

  return (
    <section className="relative py-16">
      <p className="mb-8 text-center text-xs uppercase tracking-[0.25em] text-white/40 nexora-reveal">
        Ils nous font confiance
      </p>
      <div className="nexora-marquee-mask overflow-hidden">
        <div className="nexora-marquee flex w-max items-center gap-12 whitespace-nowrap">
          {loop.map((name, i) => (
            <div
              key={i}
              className="flex items-center gap-2 text-lg font-semibold tracking-tight text-white/40 transition-colors hover:text-white/80"
            >
              <span
                className="inline-block h-2 w-2 rounded-full"
                style={{
                  background:
                    i % 2 === 0 ? "rgba(37,99,235,0.6)" : "rgba(124,58,237,0.6)",
                }}
              />
              {name}
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

/* ---------------------------------------------------------
   Section title helper
   --------------------------------------------------------- */
function SectionHeader({
  eyebrow,
  title,
  subtitle,
}: {
  eyebrow?: string
  title: React.ReactNode
  subtitle?: string
}) {
  return (
    <div className="mx-auto mb-14 max-w-3xl text-center">
      {eyebrow && (
        <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.03] px-3 py-1 text-xs font-medium text-white/70 nexora-reveal">
          {eyebrow}
        </div>
      )}
      <h2 className="nexora-reveal text-balance text-4xl font-bold tracking-tight md:text-5xl">
        {title}
      </h2>
      {subtitle && (
        <p className="nexora-reveal mt-5 text-balance text-lg leading-relaxed text-white/60">
          {subtitle}
        </p>
      )}
    </div>
  )
}

/* ---------------------------------------------------------
   4. How It Works
   --------------------------------------------------------- */
function HowItWorks() {
  return (
    <section id="how" className="relative px-5 py-28 md:px-8">
      <div className="mx-auto max-w-7xl">
        <SectionHeader
          eyebrow="Processus"
          title={<>Comment ça marche&nbsp;?</>}
          subtitle="Trois étapes simples pour accéder à des soins médicaux professionnels."
        />

        <div className="relative grid gap-6 md:grid-cols-3">
          {/* dashed connector */}
          <div
            aria-hidden
            className="pointer-events-none absolute left-[16%] right-[16%] top-20 hidden h-px md:block"
            style={{
              backgroundImage:
                "linear-gradient(to right, rgba(255,255,255,0.25) 50%, transparent 50%)",
              backgroundSize: "14px 1px",
            }}
          />

          {/* Step 1 */}
          <div className="nexora-reveal" data-delay="1">
            <GlassCard glow="blue" className="h-full">
              <div className="nexora-gradient-text text-5xl font-black leading-none">01</div>
              <div className="mt-5">
                <StepIcon variant="question" />
              </div>
              <h3 className="mt-4 text-xl font-bold">Décrivez vos symptômes</h3>
              <p className="mt-2 text-sm leading-relaxed text-white/60">
                Présentez votre situation médicale en détail via chat sécurisé.
              </p>
            </GlassCard>
          </div>

          {/* Step 2 */}
          <div className="nexora-reveal" data-delay="2">
            <GlassCard glow="purple" className="h-full">
              <div className="nexora-gradient-text text-5xl font-black leading-none">02</div>
              <div className="mt-5">
                <StepIcon variant="ai" />
              </div>
              <h3 className="mt-4 text-xl font-bold">Sélectionnez un spécialiste</h3>
              <p className="mt-2 text-sm leading-relaxed text-white/60">
                Choisissez parmi des médecins certifiés de la bonne spécialité.
              </p>
            </GlassCard>
          </div>

          {/* Step 3 */}
          <div className="nexora-reveal" data-delay="3">
            <GlassCard glow="blue" className="h-full">
              <div className="nexora-gradient-text text-5xl font-black leading-none">03</div>
              <div className="mt-5">
                <StepIcon variant="expert" />
              </div>
              <h3 className="mt-4 text-xl font-bold">Consultez en ligne</h3>
              <p className="mt-2 text-sm leading-relaxed text-white/60">
                Discutez directement avec le médecin par chat ou vidéo.
              </p>
            </GlassCard>
          </div>
        </div>
      </div>
    </section>
  )
}

/* Premium 3D-style step icons */
function StepIcon({ variant }: { variant: "question" | "ai" | "expert" }) {
  const configs = {
    question: {
      gradient: "from-[#2563EB] via-[#3b82f6] to-[#60a5fa]",
      shadowColor: "rgba(37,99,235,0.5)",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" className="h-7 w-7">
          <path
            d="M12 20h9M12 4v16m0-16c-4.418 0-8 2.239-8 5s3.582 5 8 5"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
          <path
            d="M7 9.5c0-.828 1.12-1.5 2.5-1.5s2.5.672 2.5 1.5c0 1.5-2.5 1.5-2.5 3"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
          />
          <circle cx="9.5" cy="15" r="0.5" fill="currentColor" stroke="currentColor" strokeWidth="1" />
        </svg>
      ),
    },
    ai: {
      gradient: "from-[#7C3AED] via-[#a855f7] to-[#c084fc]",
      shadowColor: "rgba(124,58,237,0.5)",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" className="h-7 w-7">
          {/* Brain/AI chip icon */}
          <rect x="4" y="4" width="16" height="16" rx="3" stroke="currentColor" strokeWidth="1.5" />
          <rect x="7" y="7" width="10" height="10" rx="1.5" stroke="currentColor" strokeWidth="1.5" />
          {/* Connection pins */}
          <path d="M9 4V2M15 4V2M9 22v-2M15 22v-2M4 9H2M4 15H2M22 9h-2M22 15h-2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
          {/* Inner pattern */}
          <circle cx="10" cy="10" r="1" fill="currentColor" />
          <circle cx="14" cy="10" r="1" fill="currentColor" />
          <circle cx="10" cy="14" r="1" fill="currentColor" />
          <circle cx="14" cy="14" r="1" fill="currentColor" />
          <path d="M10 10l4 4M14 10l-4 4" stroke="currentColor" strokeWidth="0.75" strokeLinecap="round" />
        </svg>
      ),
    },
    expert: {
      gradient: "from-[#0ea5e9] via-[#38bdf8] to-[#7dd3fc]",
      shadowColor: "rgba(14,165,233,0.5)",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" className="h-7 w-7">
          {/* Person silhouette */}
          <circle cx="12" cy="7" r="3.5" stroke="currentColor" strokeWidth="1.5" />
          <path
            d="M5.5 21c0-3.5 2.9-6.5 6.5-6.5s6.5 3 6.5 6.5"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
          />
          {/* Verification badge */}
          <circle cx="17.5" cy="6.5" r="4" fill="currentColor" />
          <path d="M15.5 6.5l1.2 1.2 2.3-2.4" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      ),
    },
  }

  const { gradient, shadowColor, icon } = configs[variant]

  return (
    <div className="relative inline-flex">
      {/* Outer glow */}
      <div
        className="absolute inset-0 rounded-2xl blur-xl opacity-60"
        style={{ background: shadowColor }}
      />
      {/* Glass container */}
      <div
        className={`relative flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br ${gradient} text-white shadow-lg`}
        style={{
          boxShadow: `0 20px 40px -15px ${shadowColor}, 0 0 0 1px rgba(255,255,255,0.1) inset`,
        }}
      >
        {/* Inner highlight */}
        <div
          className="pointer-events-none absolute inset-0 rounded-2xl"
          style={{
            background:
              "linear-gradient(135deg, rgba(255,255,255,0.25) 0%, rgba(255,255,255,0) 50%, rgba(0,0,0,0.1) 100%)",
          }}
        />
        {/* Specular top edge */}
        <div
          className="pointer-events-none absolute inset-x-2 top-0 h-px rounded-full"
          style={{
            background:
              "linear-gradient(90deg, transparent, rgba(255,255,255,0.5), transparent)",
          }}
        />
        {icon}
      </div>
    </div>
  )
}

/* ---------------------------------------------------------
   5. Features
   --------------------------------------------------------- */
function Features() {
  return (
    <section id="features" className="relative px-5 py-28 md:px-8">
      <div className="mx-auto max-w-7xl">
        <SectionHeader
          eyebrow="Fonctionnalités"
          title={<>Tout ce dont vous avez besoin</>}
          subtitle="Une plateforme de santé complète avec médecins spécialistes à votre service."
        />

        <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-3">
          {/* Médecins Certifiés */}
          <div className="nexora-reveal" data-delay="1">
            <GlassCard glow="rgba(37,99,235,0.4)" className="h-full">
              <div className="flex items-center gap-3">
                <FeatureIcon variant="ai" />
                <h3 className="text-lg font-bold">Médecins Certifiés</h3>
              </div>
              <p className="mt-4 text-sm leading-relaxed text-white/60">
                Sélectionnés et vérifiés par des organismes médicaux.
              </p>
            </GlassCard>
          </div>

          {/* Spécialistes Qualifiés */}
          <div className="nexora-reveal" data-delay="2">
            <GlassCard glow="rgba(124,58,237,0.4)" className="h-full">
              <div className="flex items-center gap-3">
                <FeatureIcon variant="expert" />
                <h3 className="text-lg font-bold">Spécialistes Qualifiés</h3>
              </div>
              <p className="mt-4 text-sm leading-relaxed text-white/60">
                Cardiologues, dermatologues, pédiatres, et plus.
              </p>
            </GlassCard>
          </div>

          {/* Sécurité HIPAA */}
          <div className="nexora-reveal" data-delay="3">
            <GlassCard glow="rgba(16,185,129,0.4)" className="h-full">
              <div className="flex items-center gap-3">
                <FeatureIcon variant="trust" />
                <h3 className="text-lg font-bold">Sécurité HIPAA</h3>
              </div>
              <p className="mt-4 text-sm leading-relaxed text-white/60">
                Vos données médicales sont strictement confidentielles.
              </p>
            </GlassCard>
          </div>

          {/* Consultations Vidéo */}
          <div className="nexora-reveal" data-delay="1">
            <GlassCard glow="rgba(244,114,182,0.4)" className="h-full">
              <div className="flex items-center gap-3">
                <FeatureIcon variant="audio" />
                <h3 className="text-lg font-bold">Consultations Vidéo</h3>
              </div>
              <p className="mt-4 text-sm leading-relaxed text-white/60">
                Chat, appel audio et vidéo HD.
              </p>
            </GlassCard>
          </div>

          {/* Disponible 24/7 */}
          <div className="nexora-reveal" data-delay="2">
            <GlassCard glow="rgba(250,204,21,0.4)" className="h-full">
              <div className="flex items-center gap-3">
                <FeatureIcon variant="instant" />
                <h3 className="text-lg font-bold">Disponible 24/7</h3>
              </div>
              <p className="mt-4 text-sm leading-relaxed text-white/60">
                Consultations jour et nuit, sans attente.
              </p>
            </GlassCard>
          </div>

          {/* Ordonnances Numériques */}
          <div className="nexora-reveal" data-delay="3">
            <GlassCard glow="rgba(56,189,248,0.4)" className="h-full">
              <div className="flex items-center gap-3">
                <FeatureIcon variant="bilingual" />
                <h3 className="text-lg font-bold">Ordonnances Numériques</h3>
              </div>
              <p className="mt-4 text-sm leading-relaxed text-white/60">
                Reçues directement via application.
              </p>
            </GlassCard>
          </div>
        </div>
      </div>
    </section>
  )
}

/* Premium 3D feature icons */
function FeatureIcon({ variant }: { variant: "ai" | "expert" | "trust" | "audio" | "instant" | "bilingual" }) {
  const configs = {
    ai: {
      gradient: "from-[#2563EB] via-[#3b82f6] to-[#60a5fa]",
      shadowColor: "rgba(37,99,235,0.5)",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" className="h-5 w-5">
          {/* Brain/neural network */}
          <circle cx="12" cy="12" r="8" stroke="currentColor" strokeWidth="1.5" />
          <circle cx="12" cy="8" r="1.5" fill="currentColor" />
          <circle cx="8" cy="12" r="1.5" fill="currentColor" />
          <circle cx="16" cy="12" r="1.5" fill="currentColor" />
          <circle cx="12" cy="16" r="1.5" fill="currentColor" />
          <path d="M12 8v3M8 12h3M13 12h3M12 13v3" stroke="currentColor" strokeWidth="1" strokeLinecap="round" />
          <path d="M9.5 9.5l1.5 1.5M14.5 9.5l-1.5 1.5M9.5 14.5l1.5-1.5M14.5 14.5l-1.5-1.5" stroke="currentColor" strokeWidth="0.75" strokeLinecap="round" />
        </svg>
      ),
    },
    expert: {
      gradient: "from-[#7C3AED] via-[#a855f7] to-[#c084fc]",
      shadowColor: "rgba(124,58,237,0.5)",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" className="h-5 w-5">
          {/* Graduation cap */}
          <path d="M12 4L2 9l10 5 10-5-10-5z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
          <path d="M6 11v5c0 2 2.7 4 6 4s6-2 6-4v-5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
          <path d="M22 9v6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
          {/* Star badge */}
          <circle cx="20" cy="17" r="3" fill="currentColor" />
          <path d="M20 15.5l.5 1h1l-.75.75.25 1.25-.75-.5-.75.5.25-1.25L19 16.5h1z" fill="white" />
        </svg>
      ),
    },
    trust: {
      gradient: "from-[#10b981] via-[#34d399] to-[#6ee7b7]",
      shadowColor: "rgba(16,185,129,0.5)",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" className="h-5 w-5">
          {/* Handshake / trust symbol */}
          <path d="M7 11l3 3 7-7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
          <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.5" />
          {/* Sparkles around */}
          <path d="M19 5l1-1M5 19l-1 1M19 19l1 1M5 5l-1-1" stroke="currentColor" strokeWidth="1" strokeLinecap="round" />
        </svg>
      ),
    },
    audio: {
      gradient: "from-[#ec4899] via-[#f472b6] to-[#f9a8d4]",
      shadowColor: "rgba(236,72,153,0.5)",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" className="h-5 w-5">
          {/* Microphone */}
          <rect x="9" y="3" width="6" height="10" rx="3" stroke="currentColor" strokeWidth="1.5" />
          <path d="M5 11a7 7 0 0014 0" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
          <path d="M12 18v3M9 21h6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
          {/* Sound waves */}
          <path d="M19 8c1 1.5 1 3.5 0 5M21 6c2 2.5 2 6.5 0 9" stroke="currentColor" strokeWidth="1" strokeLinecap="round" opacity="0.7" />
        </svg>
      ),
    },
    instant: {
      gradient: "from-[#f59e0b] via-[#fbbf24] to-[#fcd34d]",
      shadowColor: "rgba(245,158,11,0.5)",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" className="h-5 w-5">
          {/* Lightning bolt */}
          <path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z" fill="currentColor" stroke="currentColor" strokeWidth="1" strokeLinejoin="round" />
        </svg>
      ),
    },
    bilingual: {
      gradient: "from-[#0ea5e9] via-[#38bdf8] to-[#7dd3fc]",
      shadowColor: "rgba(14,165,233,0.5)",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" className="h-5 w-5">
          {/* Globe with language */}
          <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.5" />
          <ellipse cx="12" cy="12" rx="4" ry="9" stroke="currentColor" strokeWidth="1" />
          <path d="M3 12h18M4 7.5h16M4 16.5h16" stroke="currentColor" strokeWidth="1" />
          {/* Chat bubble */}
          <circle cx="18" cy="6" r="4" fill="currentColor" />
          <text x="16.5" y="8" fill="white" fontSize="5" fontWeight="bold">Aa</text>
        </svg>
      ),
    },
  }

  const { gradient, shadowColor, icon } = configs[variant]

  return (
    <div className="relative inline-flex">
      {/* Outer glow */}
      <div
        className="absolute inset-0 rounded-xl blur-lg opacity-50"
        style={{ background: shadowColor }}
      />
      {/* Glass container */}
      <div
        className={`relative flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-br ${gradient} text-white shadow-lg`}
        style={{
          boxShadow: `0 12px 24px -8px ${shadowColor}, 0 0 0 1px rgba(255,255,255,0.15) inset`,
        }}
      >
        {/* Inner highlight */}
        <div
          className="pointer-events-none absolute inset-0 rounded-xl"
          style={{
            background:
              "linear-gradient(135deg, rgba(255,255,255,0.3) 0%, rgba(255,255,255,0) 50%, rgba(0,0,0,0.1) 100%)",
          }}
        />
        {/* Specular top edge */}
        <div
          className="pointer-events-none absolute inset-x-1.5 top-0 h-px rounded-full"
          style={{
            background:
              "linear-gradient(90deg, transparent, rgba(255,255,255,0.6), transparent)",
          }}
        />
        {icon}
      </div>
    </div>
  )
}

/* ---------------------------------------------------------
   6. Domains
   --------------------------------------------------------- */
function Domains() {
  return (
    <section id="domains" className="relative px-5 py-28 md:px-8">
      <div className="mx-auto max-w-7xl">
        <SectionHeader
          eyebrow="Spécialités"
          title={<>8 spécialités médicales</>}
          subtitle="Consultez des experts dans votre domaine de santé."
        />
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:gap-5 lg:grid-cols-4">
          <DomainCard variant="medicine" name="Médecine générale" delay="1" />
          <DomainCard variant="law" name="Cardiologie" delay="2" />
          <DomainCard variant="tax" name="Dermatologie" delay="3" />
          <DomainCard variant="admin" name="Pédiatrie" delay="4" />
          <DomainCard variant="finance" name="Gynécologie" delay="1" />
          <DomainCard variant="tech" name="Psychiatrie" delay="2" />
          <DomainCard variant="education" name="Ophtalmologie" delay="3" />
          <DomainCard variant="startup" name="Dentisterie" delay="4" />
        </div>
      </div>
    </section>
  )
}

/* Clean monochromatic domain card */
function DomainCard({
  variant,
  name,
  delay,
}: {
  variant: "medicine" | "law" | "tax" | "admin" | "finance" | "tech" | "education" | "startup"
  name: string
  delay: string
}) {
  const icons = {
    medicine: (
      <svg viewBox="0 0 24 24" fill="none" className="h-6 w-6">
        <path d="M12 6v12M6 12h12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
        <rect x="3" y="3" width="18" height="18" rx="4" stroke="currentColor" strokeWidth="1.5" />
      </svg>
    ),
    law: (
      <svg viewBox="0 0 24 24" fill="none" className="h-6 w-6">
        <path d="M12 3v18M5 7h14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
        <path d="M5 7l-2 7h6l-2-7M19 7l-2 7h6l-2-7" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
        <path d="M8 21h8" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
      </svg>
    ),
    tax: (
      <svg viewBox="0 0 24 24" fill="none" className="h-6 w-6">
        <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="1.5" />
        <path d="M12 7v2M12 15v2M9 9.5c0-.83.67-1.5 1.5-1.5h1c1.1 0 2 .9 2 2s-.9 2-2 2h-1c-1.1 0-2 .9-2 2s.9 2 2 2h1c.83 0 1.5-.67 1.5-1.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
      </svg>
    ),
    admin: (
      <svg viewBox="0 0 24 24" fill="none" className="h-6 w-6">
        <path d="M3 21h18" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
        <path d="M5 21V10M9 21V10M15 21V10M19 21V10" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
        <path d="M12 3l10 7H2l10-7z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
      </svg>
    ),
    finance: (
      <svg viewBox="0 0 24 24" fill="none" className="h-6 w-6">
        <path d="M3 20l5-5 4 4 9-11" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        <path d="M17 4h4v4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    ),
    tech: (
      <svg viewBox="0 0 24 24" fill="none" className="h-6 w-6">
        <rect x="2" y="4" width="20" height="16" rx="2" stroke="currentColor" strokeWidth="1.5" />
        <path d="M7 9l3 3-3 3M13 15h5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    ),
    education: (
      <svg viewBox="0 0 24 24" fill="none" className="h-6 w-6">
        <path d="M12 4L2 9l10 5 10-5-10-5z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
        <path d="M6 11v5c0 2 2.7 4 6 4s6-2 6-4v-5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
      </svg>
    ),
    startup: (
      <svg viewBox="0 0 24 24" fill="none" className="h-6 w-6">
        <path d="M12 2C9.5 5.5 9 10 12 14M12 14l-3 4.5 3-2 3 2-3-4.5z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
        <path d="M8 10c-2 0-3.5 1-4.5 2.5M16 10c2 0 3.5 1 4.5 2.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
      </svg>
    ),
  }

  return (
    <div className="nexora-reveal" data-delay={delay}>
      <div className="group relative flex h-full cursor-pointer flex-col items-center justify-center rounded-2xl border border-white/[0.06] bg-white/[0.02] py-10 text-center backdrop-blur-sm transition-all duration-300 hover:border-white/[0.12] hover:bg-white/[0.04]">
        {/* Subtle brand glow on hover */}
        <div
          className="pointer-events-none absolute inset-0 rounded-2xl opacity-0 transition-opacity duration-300 group-hover:opacity-100"
          style={{
            background:
              "radial-gradient(ellipse at 50% 0%, rgba(37,99,235,0.08) 0%, transparent 70%)",
          }}
        />
        {/* Icon container */}
        <div className="relative flex h-14 w-14 items-center justify-center rounded-2xl border border-white/[0.08] bg-white/[0.03] text-white/50 transition-all duration-300 group-hover:border-[#2563EB]/30 group-hover:bg-[#2563EB]/10 group-hover:text-white">
          {/* Top highlight */}
          <div
            className="pointer-events-none absolute inset-x-3 top-0 h-px rounded-full opacity-40"
            style={{
              background: "linear-gradient(90deg, transparent, rgba(255,255,255,0.5), transparent)",
            }}
          />
          {icons[variant]}
        </div>
        <div className="mt-4 text-sm font-medium text-white/70 transition-colors duration-300 group-hover:text-white">
          {name}
        </div>
      </div>
    </div>
  )
}

/* ---------------------------------------------------------
   7. Live Demo (typewriter)
   --------------------------------------------------------- */
function LiveDemo() {
  const full =
    "Bonjour ! Des douleurs thoraciques peuvent avoir plusieurs causes. Voici ce que je recommande : 1) Décrivez la localisation exacte de la douleur, 2) Notez si elle irradie vers le bras ou la mâchoire, 3) Un ECG est conseillé rapidement, 4) Je vous oriente vers le Dr. Amrani, cardiologue certifié, disponible maintenant."
  const [typed, setTyped] = useState("")
  const [showTyping, setShowTyping] = useState(true)
  const [started, setStarted] = useState(false)
  const ref = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    if (!ref.current) return
    const obs = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            setStarted(true)
            obs.disconnect()
          }
        }
      },
      { threshold: 0.3 },
    )
    obs.observe(ref.current)
    return () => obs.disconnect()
  }, [])

  useEffect(() => {
    if (!started) return
    const typingDelay = setTimeout(() => {
      setShowTyping(false)
      let i = 0
      const interval = setInterval(() => {
        i++
        setTyped(full.slice(0, i))
        if (i >= full.length) clearInterval(interval)
      }, 22)
      return () => clearInterval(interval)
    }, 1400)
    return () => clearTimeout(typingDelay)
  }, [started])

  return (
    <section id="demo" ref={ref} className="relative px-5 py-28 md:px-8">
      <div className="mx-auto max-w-5xl">
        <SectionHeader
          eyebrow="Démo en direct"
          title={<>Voyez Nexora en action</>}
          subtitle="Une conversation réelle, simulée sous vos yeux."
        />

        <div className="nexora-reveal rounded-3xl border border-white/10 bg-white/[0.03] p-2 backdrop-blur-xl shadow-[0_40px_120px_-30px_rgba(37,99,235,0.35)]">
          <div className="overflow-hidden rounded-2xl border border-white/10 bg-[#0b1120]/90">
            <div className="flex items-center gap-2 border-b border-white/10 px-4 py-3">
              <span className="h-3 w-3 rounded-full bg-[#ff5f57]" />
              <span className="h-3 w-3 rounded-full bg-[#febc2e]" />
              <span className="h-3 w-3 rounded-full bg-[#28c840]" />
              <div className="mx-auto flex items-center gap-2 rounded-md border border-white/5 bg-white/[0.03] px-3 py-1 text-xs text-white/50">
                <Shield className="h-3 w-3 text-emerald-400" />
                nexora.ma/chat
              </div>
            </div>

            <div className="space-y-4 p-6 md:p-8">
              {/* user */}
              <div className="flex justify-end">
                <div
                  className="max-w-[80%] rounded-2xl rounded-br-md px-4 py-3 text-left text-sm text-white shadow-lg"
                  style={{
                    background:
                      "linear-gradient(135deg, rgba(37,99,235,0.95) 0%, rgba(124,58,237,0.95) 100%)",
                  }}
                >
                  J&apos;ai des douleurs thoraciques depuis 2 jours, que faire&nbsp;?
                </div>
              </div>

              {/* typing or AI answer */}
              <div className="flex justify-start">
                <div className="max-w-[85%] rounded-2xl rounded-bl-md border border-[#7C3AED]/40 bg-white/[0.04] px-4 py-3 text-left text-sm text-white/90 backdrop-blur-md shadow-[0_0_40px_-15px_rgba(124,58,237,0.7)]">
                  <div className="mb-2 flex items-center gap-2 text-xs font-semibold text-[#c084fc]">
                    <Sparkles className="h-3.5 w-3.5" />
                    Nexora IA
                  </div>
                  {started && showTyping ? (
                    <div className="flex items-center gap-1.5 py-1">
                      <span className="nexora-bounce-dot h-2 w-2 rounded-full bg-white/70" />
                      <span
                        className="nexora-bounce-dot h-2 w-2 rounded-full bg-white/70"
                        style={{ animationDelay: "0.15s" }}
                      />
                      <span
                        className="nexora-bounce-dot h-2 w-2 rounded-full bg-white/70"
                        style={{ animationDelay: "0.3s" }}
                      />
                    </div>
                  ) : (
                    <p className="leading-relaxed">
                      {typed}
                      {typed.length < full.length && (
                        <span className="nexora-blink ml-0.5 inline-block h-4 w-[2px] translate-y-0.5 bg-[#c084fc]" />
                      )}
                    </p>
                  )}
                </div>
              </div>

              {/* Footer badges */}
              <div className="flex flex-wrap items-center justify-between gap-3 pt-2">
                <div className="flex items-center gap-2 rounded-full border border-emerald-400/20 bg-emerald-400/10 px-3 py-1 text-xs text-emerald-300">
                  <span className="relative flex h-2 w-2">
                    <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-60" />
                    <span className="relative inline-flex h-2 w-2 rounded-full bg-emerald-400" />
                  </span>
                  Confiance IA : 94%
                </div>
                <div className="flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.04] px-3 py-1 text-xs text-white/80">
                  <span
                    className="flex h-5 w-5 items-center justify-center rounded-full text-xs"
                    style={{
                      background: "linear-gradient(135deg, #2563EB, #7C3AED)",
                    }}
                  >
                    <Stethoscope className="h-3 w-3" />
                  </span>
                  Dr. Amrani K.
                  <span className="flex items-center gap-0.5 text-amber-300">
                    <Star className="h-3 w-3 fill-amber-300" />
                    4.9
                  </span>
                  <span className="text-emerald-300">— disponible</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

/* ---------------------------------------------------------
   8. Stats (count up)
   --------------------------------------------------------- */
function Stats() {
  const stats = [
    { target: 10000, suffix: "+", label: "Questions répondues", display: "10 000+" },
    { target: 500, suffix: "+", label: "Experts certifiés" },
    { target: 94, suffix: "%", label: "Taux de satisfaction" },
    { target: 3, prefix: "< ", suffix: "s", label: "Temps de réponse" },
  ]

  const ref = useRef<HTMLDivElement | null>(null)
  const [run, setRun] = useState(false)

  useEffect(() => {
    if (!ref.current) return
    const obs = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            setRun(true)
            obs.disconnect()
          }
        }
      },
      { threshold: 0.35 },
    )
    obs.observe(ref.current)
    return () => obs.disconnect()
  }, [])

  return (
    <section ref={ref} className="relative px-5 py-20 md:px-8">
      <div className="mx-auto max-w-7xl">
        <div className="relative overflow-hidden rounded-3xl border border-white/10 bg-white/[0.03] backdrop-blur-xl nexora-reveal">
          <div
            className="absolute inset-x-0 top-0 h-px"
            style={{
              background:
                "linear-gradient(90deg, transparent, #2563EB 35%, #7C3AED 65%, transparent)",
            }}
          />
          <div className="grid grid-cols-2 gap-6 p-10 md:grid-cols-4 md:p-14">
            {stats.map((s, i) => (
              <div key={i} className="text-center">
                <div className="nexora-gradient-text text-4xl font-extrabold tracking-tight md:text-5xl">
                  <CountUp
                    run={run}
                    target={s.target}
                    prefix={s.prefix}
                    suffix={s.suffix}
                    display={s.display}
                  />
                </div>
                <div className="mt-2 text-sm text-white/60">{s.label}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}

function CountUp({
  run,
  target,
  prefix = "",
  suffix = "",
  display,
}: {
  run: boolean
  target: number
  prefix?: string
  suffix?: string
  display?: string
}) {
  const [val, setVal] = useState(0)
  useEffect(() => {
    if (!run) return
    const duration = 1600
    const start = performance.now()
    let raf = 0
    const tick = (t: number) => {
      const p = Math.min(1, (t - start) / duration)
      const eased = 1 - Math.pow(1 - p, 3)
      setVal(Math.round(target * eased))
      if (p < 1) raf = requestAnimationFrame(tick)
    }
    raf = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(raf)
  }, [run, target])

  let text: string
  if (display && val >= target) text = display
  else if (target >= 1000) text = val.toLocaleString("fr-FR").replace(/,/g, " ") + suffix
  else text = `${prefix}${val}${suffix}`
  return <span>{text}</span>
}

/* ---------------------------------------------------------
   9. Testimonials (auto-slide)
   --------------------------------------------------------- */
function Testimonials() {
  const items = [
    {
      quote:
        "J'ai consulté un cardiologue en 15 minutes pour une palpitation inquiétante. Diagnostic clair et rassurant.",
      author: "Karim B.",
      city: "Casablanca",
    },
    {
      quote:
        "Mon enfant avait une otite. Une pédiatre certifiée m'a prescrit un traitement efficace le même jour.",
      author: "Fatima Z.",
      city: "Rabat",
    },
    {
      quote:
        "Excellente consultation dermatologique pour un problème de peau. Le médecin était très attentif et professionnel.",
      author: "Youssef M.",
      city: "Marrakech",
    },
  ]
  const [idx, setIdx] = useState(0)
  useEffect(() => {
    const id = setInterval(() => setIdx((i) => (i + 1) % items.length), 4000)
    return () => clearInterval(id)
  }, [items.length])

  return (
    <section className="relative px-5 py-28 md:px-8">
      <div className="mx-auto max-w-6xl">
        <SectionHeader
          eyebrow="Témoignages"
          title={<>Ce que disent nos utilisateurs</>}
        />

        {/* Desktop: grid of 3 always */}
        <div className="hidden gap-5 md:grid md:grid-cols-3">
          {items.map((t, i) => (
            <div key={i} className="nexora-reveal" data-delay={i + 1}>
              <TestimonialCard {...t} highlighted={i === idx} />
            </div>
          ))}
        </div>

        {/* Mobile: single carousel */}
        <div className="md:hidden">
          <div className="overflow-hidden rounded-2xl">
            <div
              className="flex transition-transform duration-700 ease-out"
              style={{ transform: `translateX(-${idx * 100}%)` }}
            >
              {items.map((t, i) => (
                <div key={i} className="w-full shrink-0 px-1">
                  <TestimonialCard {...t} highlighted />
                </div>
              ))}
            </div>
          </div>
          <div className="mt-5 flex justify-center gap-2">
            {items.map((_, i) => (
              <button
                key={i}
                aria-label={`Témoignage ${i + 1}`}
                onClick={() => setIdx(i)}
                className={`h-1.5 rounded-full transition-all ${
                  i === idx ? "w-6 bg-white" : "w-1.5 bg-white/30"
                }`}
              />
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}

function TestimonialCard({
  quote,
  author,
  city,
  highlighted,
}: {
  quote: string
  author: string
  city: string
  highlighted?: boolean
}) {
  return (
    <div
      className={`relative h-full rounded-2xl border bg-white/[0.03] p-7 backdrop-blur-xl transition-all duration-500 ${
        highlighted
          ? "border-white/20 shadow-[0_20px_60px_-20px_rgba(124,58,237,0.45)]"
          : "border-white/10"
      }`}
    >
      <div className="flex gap-1 text-amber-400">
        {Array.from({ length: 5 }).map((_, i) => (
          <Star key={i} className="h-4 w-4 fill-amber-400" />
        ))}
      </div>
      <p className="mt-4 text-base leading-relaxed text-white/85">&ldquo;{quote}&rdquo;</p>
      <div className="mt-6 flex items-center gap-3 border-t border-white/10 pt-4">
        <div
          className="flex h-9 w-9 items-center justify-center rounded-full text-sm font-bold text-white"
          style={{ background: "linear-gradient(135deg, #2563EB, #7C3AED)" }}
        >
          {author[0]}
        </div>
        <div>
          <div className="text-sm font-semibold">{author}</div>
          <div className="text-xs text-white/50">{city}</div>
        </div>
      </div>
    </div>
  )
}

/* ---------------------------------------------------------
   10. Pricing
   --------------------------------------------------------- */
function PricingCard({
  icon, name, price, period, badge, badgeGradient, highlight, glow,
  features, locked, consultations, cta, ctaHref, ctaGradient,
  delay,
}: {
  icon: string; name: string; price: number | string; period?: string;
  badge?: string; badgeGradient?: string; highlight?: boolean; glow?: boolean;
  features: string[]; locked?: string[]; consultations?: number;
  cta: string; ctaHref: string; ctaGradient?: string; delay: number;
}) {
  return (
    <div className={`nexora-reveal relative flex flex-col${highlight ? ' z-10' : ''}`} data-delay={delay}>
      {glow && (
        <div
          aria-hidden
          className="absolute -inset-[1px] rounded-3xl opacity-70 blur-[2px]"
          style={{ background: "linear-gradient(135deg,#6d28d9,#7c3aed,#2563eb)" }}
        />
      )}
      <div
        className={`relative flex h-full flex-col rounded-3xl border p-8 backdrop-blur-xl${
          highlight
            ? ' border-[#7C3AED]/40 bg-[#0b1120]/80 shadow-[0_30px_80px_-20px_rgba(124,58,237,0.4)]'
            : ' border-white/10 bg-white/[0.03]'
        }`}
      >
        {badge && (
          <div
            className="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full px-3 py-1 text-xs font-bold tracking-wide uppercase text-white"
            style={{ background: badgeGradient ?? "linear-gradient(135deg,#2563EB,#7C3AED)" }}
          >
            {badge}
          </div>
        )}

        <div className="flex items-center gap-3 text-sm text-white/70">
          <span className="text-2xl">{icon}</span>
          {name}
        </div>

        <div className="mt-5">
          {typeof price === 'number' && price === 0 ? (
            <>
              <div className="nexora-gradient-text text-5xl font-extrabold tracking-tight">Gratuit</div>
              <div className="mt-1 text-sm text-white/50">pour toujours</div>
            </>
          ) : (
            <>
              <div className="flex items-baseline gap-1">
                <span className="nexora-gradient-text text-5xl font-extrabold tracking-tight">{price}</span>
                <span className="text-lg font-semibold text-white/60">MAD</span>
              </div>
              <div className="mt-1 text-sm text-white/50">{period}</div>
            </>
          )}
        </div>

        {consultations != null && consultations > 0 && (
          <div className="mt-4 inline-flex items-center gap-2 rounded-full border border-[#2563EB]/30 bg-[#2563EB]/10 px-3 py-1.5 text-xs font-semibold text-blue-300">
            <Zap className="h-3 w-3" />
            {consultations} consultation{consultations > 1 ? 's' : ''} médecin / mois
          </div>
        )}

        <ul className="mt-7 space-y-3 text-sm flex-1">
          {features.map((f) => (
            <li key={f} className="flex items-start gap-3 text-white/85">
              <span
                className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full text-white"
                style={{ background: ctaGradient ?? "rgba(255,255,255,0.08)" }}
              >
                <Check className="h-3 w-3" />
              </span>
              {f}
            </li>
          ))}
          {(locked ?? []).map((f) => (
            <li key={f} className="flex items-start gap-3 text-white/35">
              <span className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-white/[0.04]">
                <X className="h-3 w-3" />
              </span>
              {f}
            </li>
          ))}
        </ul>

        <div className="mt-8">
          {ctaGradient ? (
            <GradientButton href={ctaHref} size="lg" className="w-full justify-center">
              {cta}
              <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
            </GradientButton>
          ) : (
            <GhostButton href={ctaHref} size="lg" className="w-full justify-center">
              {cta}
            </GhostButton>
          )}
        </div>
      </div>
    </div>
  )
}

function Pricing() {
  return (
    <section id="pricing" className="relative px-5 py-28 md:px-8">
      <div className="mx-auto max-w-6xl">
        <SectionHeader
          eyebrow="Tarifs"
          title={<>Un abonnement simple, transparent</>}
          subtitle="L'IA est toujours gratuite. Passez à Pro ou Premium pour consulter de vrais médecins certifiés."
        />

        <div className="grid gap-6 md:grid-cols-3 md:items-stretch">
          <PricingCard
            delay={1}
            icon="🤖"
            name="Gratuit"
            price={0}
            features={[
              "Assistant IA médical 24h/24",
              "Triage des symptômes",
              "Support français & arabe",
              "Historique illimité",
              "Messages vocaux",
            ]}
            locked={[
              "Consultations avec médecin",
              "Accès aux spécialistes",
            ]}
            cta="Commencer gratuitement"
            ctaHref="/register"
          />

          <PricingCard
            delay={2}
            icon="⚡"
            name="Pro"
            price={249}
            period="par mois"
            badge="Populaire"
            badgeGradient="linear-gradient(135deg,#1d4ed8,#2563eb)"
            consultations={3}
            features={[
              "Tout le plan Gratuit",
              "3 consultations médecin / mois",
              "Médecins certifiés & vérifiés",
              "Réponse sous 15 minutes",
              "Paiement sécurisé (Stripe + CMI)",
            ]}
            cta="Choisir Pro"
            ctaHref="/register"
            ctaGradient="linear-gradient(135deg,#1d4ed8,#2563eb)"
          />

          <PricingCard
            delay={3}
            icon="👑"
            name="Premium"
            price={449}
            period="par mois"
            badge="Meilleure valeur"
            badgeGradient="linear-gradient(135deg,#6d28d9,#7c3aed)"
            highlight
            glow
            consultations={6}
            features={[
              "Tout le plan Pro",
              "6 consultations médecin / mois",
              "Médecins prioritaires (top rating)",
              "Réponse sous 5 minutes",
              "Support dédié",
            ]}
            cta="Choisir Premium"
            ctaHref="/register"
            ctaGradient="linear-gradient(135deg,#6d28d9,#7c3aed,#a855f7)"
          />
        </div>

        {/* Extra credit note */}
        <div className="nexora-reveal mt-6">
          <div className="flex items-start gap-3 rounded-2xl border border-white/10 bg-white/[0.03] p-5 text-sm text-white/75 backdrop-blur-xl">
            <span className="text-lg">💡</span>
            <p>
              Crédits épuisés avant la fin du mois ?{" "}
              <span className="font-semibold text-white">Achetez une consultation supplémentaire à 89 MAD</span>{" "}
              depuis votre espace sans changer de plan. Aucun engagement, annulation à tout moment.
            </p>
          </div>
        </div>
      </div>
    </section>
  )
}

/* ---------------------------------------------------------
   11. FAQ
   --------------------------------------------------------- */
function FAQ() {
  const faqs = [
    {
      q: "Les médecins sur Nexora sont-ils vraiment certifiés ?",
      a: "Oui, tous nos médecins sont vérifiés : diplômes, licence professionnelle, assurance et références. Chaque profil est validé par notre équipe avant d'être actif.",
    },
    {
      q: "Comment choisir le bon spécialiste ?",
      a: "Vous pouvez consulter le profil, l'expérience et les avis des médecins. Notre système vous recommande aussi les spécialistes les mieux adaptés à votre situation.",
    },
    {
      q: "Est-ce que les consultations sont confidentielles ?",
      a: "Absolument. Toutes les consultations sont protégées selon les normes HIPAA. Vos données médicales restent privées et ne sont jamais partagées.",
    },
    {
      q: "Combien coûte une consultation ?",
      a: "Nexora fonctionne par abonnement : le plan Pro à 249 MAD/mois inclut 3 consultations médecin, et le plan Premium à 449 MAD/mois en inclut 6. Si vous épuisez vos crédits, vous pouvez acheter une consultation supplémentaire à 89 MAD sans changer de plan.",
    },
    {
      q: "Puis-je obtenir une ordonnance numérique ?",
      a: "Oui. Après la consultation, le médecin peut vous envoyer directement une ordonnance numérique que vous pouvez utiliser en pharmacie.",
    },
    {
      q: "Que faire si je ne suis pas satisfait ?",
      a: "Si vous n'êtes pas satisfait, demandez un remboursement complet dans les 24 heures suivant la consultation. Aucune question posée.",
    },
  ]
  const [openIdx, setOpenIdx] = useState<number | null>(0)

  return (
    <section id="faq" className="relative px-5 py-28 md:px-8">
      <div className="mx-auto max-w-3xl">
        <SectionHeader
          eyebrow="FAQ"
          title={<>Questions fréquentes</>}
        />
        <div className="space-y-3">
          {faqs.map((f, i) => {
            const isOpen = openIdx === i
            return (
              <div
                key={i}
                className="nexora-reveal rounded-2xl border border-white/10 bg-white/[0.03] backdrop-blur-xl transition-all duration-300 hover:border-white/20"
                data-delay={(i % 4) + 1}
              >
                <button
                  className="flex w-full items-center justify-between gap-4 p-5 text-left"
                  onClick={() => setOpenIdx(isOpen ? null : i)}
                  aria-expanded={isOpen}
                >
                  <span className="text-base font-semibold text-white">{f.q}</span>
                  <ChevronDown
                    className={`h-5 w-5 shrink-0 text-white/60 transition-transform duration-300 ${
                      isOpen ? "rotate-180 text-white" : ""
                    }`}
                  />
                </button>
                <div
                  className="grid overflow-hidden transition-[grid-template-rows] duration-500 ease-in-out"
                  style={{ gridTemplateRows: isOpen ? "1fr" : "0fr" }}
                >
                  <div className="min-h-0">
                    <p className="px-5 pb-5 text-sm leading-relaxed text-white/65">{f.a}</p>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}

/* ---------------------------------------------------------
   12. Final CTA
   --------------------------------------------------------- */
function FinalCTA() {
  return (
    <section className="relative px-5 py-28 md:px-8">
      <div className="mx-auto max-w-5xl">
        <div className="relative nexora-reveal">
          <div
            aria-hidden
            className="absolute -inset-[1px] rounded-[32px] opacity-80 blur-[1px]"
            style={{
              background: "linear-gradient(135deg, #2563EB, #7C3AED, #2563EB)",
              backgroundSize: "200% 200%",
              animation: "nexora-gradient-pan 8s ease-in-out infinite",
            }}
          />
          <div className="relative overflow-hidden rounded-[32px] border border-white/10 bg-[#0b1120]/90 p-10 text-center backdrop-blur-xl md:p-16">
            <div
              aria-hidden
              className="absolute -left-24 -top-24 h-64 w-64 rounded-full blur-3xl"
              style={{ background: "#2563EB", opacity: 0.25 }}
            />
            <div
              aria-hidden
              className="absolute -right-24 -bottom-24 h-64 w-64 rounded-full blur-3xl"
              style={{ background: "#7C3AED", opacity: 0.25 }}
            />
            <h2 className="relative text-balance text-4xl font-bold tracking-tight md:text-5xl">
              Prenez soin de votre santé
              <br className="hidden sm:block" /> avec des experts certifiés
            </h2>
            <p className="relative mx-auto mt-5 max-w-xl text-balance text-lg text-white/65">
              Rejoignez plus de 10 000 patients qui ont consulté des médecins spécialistes via Nexora.
            </p>
            <div className="relative mt-9 flex justify-center">
              <GradientButton href="/register" size="lg">
                Créer mon compte — consultez un médecin
                <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
              </GradientButton>
            </div>
            <div className="relative mt-6 flex flex-wrap items-center justify-center gap-x-6 gap-y-2 text-sm text-white/55">
              <span className="inline-flex items-center gap-1.5">
                <Check className="h-4 w-4 text-emerald-400" /> Médecins certifiés
              </span>
              <span className="inline-flex items-center gap-1.5">
                <Check className="h-4 w-4 text-emerald-400" /> Données sécurisées
              </span>
              <span className="inline-flex items-center gap-1.5">
                <Check className="h-4 w-4 text-emerald-400" /> 24/7 disponible
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

/* ---------------------------------------------------------
   13. Footer
   --------------------------------------------------------- */
function Footer() {
  const cols: { title: string; items: string[] }[] = [
    {
      title: "Plateforme",
      items: ["Fonctionnalités", "Comment ça marche", "Médecins", "FAQ"],
    },
    {
      title: "Spécialités",
      items: ["Cardiologie", "Dermatologie", "Pédiatrie", "Gynécologie"],
    },
    {
      title: "Légal",
      items: ["CGU", "Confidentialité", "Cookies", "Contact"],
    },
  ]
  return (
    <footer className="relative mt-16 px-5 pb-10 md:px-8">
      <div
        aria-hidden
        className="mx-auto h-px max-w-7xl"
        style={{
          background:
            "linear-gradient(90deg, transparent, #2563EB 40%, #7C3AED 60%, transparent)",
        }}
      />
      <div className="mx-auto grid max-w-7xl gap-10 py-14 md:grid-cols-12">
        <div className="md:col-span-4">
          <Logo iconSize={34} wordmarkClass="text-xl" />
          <p className="mt-4 max-w-xs text-sm leading-relaxed text-white/55">
            Votre plateforme de santé numérique. Consultez des médecins certifiés en ligne, 24/7.
          </p>
          <div className="mt-5 flex gap-2">
            {[
              { Icon: Globe2, label: "LinkedIn" },
              { Icon: Globe2, label: "Twitter" },
              { Icon: Globe2, label: "Instagram" },
            ].map(({ Icon, label }) => (
              <a
                key={label}
                href="#"
                aria-label={label}
                className="inline-flex h-10 w-10 items-center justify-center rounded-full border border-white/10 bg-white/[0.03] text-white/70 transition-all hover:border-white/25 hover:text-white hover:shadow-[0_0_30px_-8px_rgba(124,58,237,0.6)]"
              >
                <Icon className="h-4 w-4" />
              </a>
            ))}
          </div>
        </div>

        {cols.map((c) => (
          <div key={c.title} className="md:col-span-2 lg:col-span-2">
            <div className="text-sm font-semibold text-white">{c.title}</div>
            <ul className="mt-4 space-y-2.5 text-sm text-white/55">
              {c.items.map((it) => (
                <li key={it}>
                  <a href="#" className="transition-colors hover:text-white">
                    {it}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        ))}

        <div className="md:col-span-2">
          <div className="text-sm font-semibold text-white">Newsletter</div>
          <p className="mt-3 text-xs text-white/55">
            Recevez nos actualités et astuces.
          </p>
          <form
            onSubmit={(e) => e.preventDefault()}
            className="mt-4 flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.03] p-1 backdrop-blur-md"
          >
            <input
              type="email"
              placeholder="Votre email"
              className="w-full bg-transparent px-3 py-2 text-xs text-white placeholder:text-white/40 focus:outline-none"
            />
            <button
              type="submit"
              className="inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-white"
              style={{ background: "linear-gradient(135deg, #2563EB, #7C3AED)" }}
              aria-label="S'abonner"
            >
              <ArrowRight className="h-4 w-4" />
            </button>
          </form>
        </div>
      </div>

      <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-2 border-t border-white/10 pt-6 text-xs text-white/45 md:flex-row">
        <div>© 2026 Nexora — Soins médicaux numériques</div>
        <div>Fait avec ❤️ pour votre santé</div>
      </div>
    </footer>
  )
}

/* ---------------------------------------------------------
   Scroll reveal observer
   --------------------------------------------------------- */
function ScrollReveal() {
  useEffect(() => {
    const els = document.querySelectorAll<HTMLElement>(".nexora-reveal")
    const obs = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            e.target.classList.add("is-visible")
            obs.unobserve(e.target)
          }
        }
      },
      { threshold: 0.12, rootMargin: "0px 0px -60px 0px" },
    )
    els.forEach((el) => obs.observe(el))
    return () => obs.disconnect()
  }, [])
  return null
}
