'use client';

import React, { useCallback, useEffect, useRef, useState, Suspense } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { ChatInput } from '@/components/thread/chat-input/chat-input';
import { Examples } from '@/components/dashboard/examples';
import { FeatureSection } from '@/components/home/sections/feature-section';
import { UseCasesSection } from '@/components/home/sections/use-cases-section';
import { QuoteSection } from '@/components/home/sections/quote-section';
import { FAQSection } from '@/components/home/sections/faq-section';
import { ThemeToggle } from '@/components/home/theme-toggle';
import { HeroVideoSection } from '@/components/home/sections/hero-video-section';
import { VisionPipeline } from '@/components/home/sections/vision-pipeline';

// Shared key used by the real dashboard to auto-submit after login
const PENDING_PROMPT_KEY = 'pendingAgentPrompt';

function PublicDashboardContent() {
  const router = useRouter();
  const [value, setValue] = useState('');
  const [redirecting, setRedirecting] = useState(false);

  // Restore any draft when returning from auth cancellation
  useEffect(() => {
    const draft = localStorage.getItem(PENDING_PROMPT_KEY);
    if (draft) setValue(draft);
  }, []);

  // Prefetch auth and dashboard shell for fast handoff
  useEffect(() => {
    try {
      router.prefetch('/auth');
      router.prefetch('/dashboard');
    } catch {}
  }, [router]);

  // Navbar remains fully transparent; no scroll effects

  const buildAuthUrl = useCallback((prompt: string | undefined) => {
    const text = (prompt || '').trim();
    if (text) {
      try {
        localStorage.setItem(PENDING_PROMPT_KEY, text);
      } catch {}
      try {
        sessionStorage.setItem(PENDING_PROMPT_KEY, text);
      } catch {}
    }
    const truncated = text.slice(0, 1000);
    const encoded = encodeURIComponent(truncated);
    const returnUrl = `/dashboard${encoded ? `?prefill=${encoded}` : ''}`;
    return `/auth?returnUrl=${encodeURIComponent(returnUrl)}`;
  }, []);

  const handleSubmit = useCallback(() => {
    setRedirecting(true);
    const url = buildAuthUrl(value);
    setTimeout(() => {
      window.location.href = url;
    }, 50);
  }, [buildAuthUrl, value]);

  const handleChange = useCallback((next: string) => {
    setValue(next);
  }, []);

  const handleSelectPrompt = useCallback((q: string) => {
    setValue(q);
  }, []);

  const onSignInClick = useCallback(() => {
    const url = buildAuthUrl(value);
    window.location.href = url;
  }, [buildAuthUrl, value]);

  const onDiscoverClick = useCallback(() => {
    const el = document.getElementById('discover');
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }, []);

  // SEO/meta friendly H1 (visually hidden)
  const H1 = <h1 className="sr-only">Iris — Chat Dashboard</h1>;

  return (
    <div className="min-h-screen w-full overflow-x-hidden">
      {H1}
      {/* Top Nav */}
      <div className={"sticky top-0 z-30 w-full bg-transparent"}>
        <div className="mx-auto flex h-14 max-w-7xl items-center justify-between px-4">
          <div className="flex items-center gap-2">
            <div className="h-6 w-6 rounded bg-gradient-to-br from-indigo-400 to-blue-500 shadow-sm" />
            <span className="text-sm font-medium tracking-wide">Iris</span>
          </div>
          <div className="flex items-center gap-2">
            <ThemeToggle />
            <Button onClick={onDiscoverClick} variant="ghost" className="h-8 px-3">
              Discover
            </Button>
            <Button onClick={onSignInClick} variant="default" className="h-8 px-3">
              Sign in
            </Button>
          </div>
        </div>
      </div>

      {/* Hero: Chat-like dashboard view */}
      <section className="relative flex min-h-[calc(100vh-56px)] w-full items-center justify-center px-4">
        {/* Soft grid background */}
        <div className="pointer-events-none absolute inset-0 [mask-image:radial-gradient(circle_at_center,black_40%,transparent_70%)]">
          <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,rgba(120,120,255,0.08),transparent_60%),radial-gradient(ellipse_at_bottom,rgba(0,0,0,0.3),transparent_60%)]" />
          <div className="absolute inset-0 bg-[linear-gradient(to_right,rgba(120,120,120,0.15)_1px,transparent_1px),linear-gradient(to_bottom,rgba(120,120,120,0.15)_1px,transparent_1px)] bg-[size:32px_32px] opacity-30" />
        </div>

        <div className="relative z-10 w-full max-w-[700px]">
          <div className="mb-6 text-center">
            <p className="text-2xl md:text-3xl tracking-tight text-foreground/90">
              What would you like to do today?
            </p>
          </div>
          <ChatInput
            onSubmit={handleSubmit}
            placeholder="Describe what you need help with..."
            value={value}
            onChange={handleChange}
            loading={redirecting}
            disabled={false}
            hideAttachments={true}
            isLoggedIn={false}
            enableAdvancedConfig={false}
          />
          {redirecting && (
            <div className="mt-2 text-xs text-muted-foreground">
              Sign in required — redirecting…
            </div>
          )}
          <div className="mt-6">
            <Examples onSelectPrompt={handleSelectPrompt} count={4} />
          </div>
        </div>

        {/* Scroll hint */}
        <button
          onClick={onDiscoverClick}
          className="group absolute bottom-6 left-1/2 z-10 -translate-x-1/2 rounded-full border border-border bg-background/70 px-3 py-2 text-xs text-muted-foreground shadow-sm backdrop-blur transition hover:bg-background"
        >
          <span className="mr-2 align-middle">Discover what Iris can do</span>
          <span className="inline-flex -translate-y-[1px] items-center gap-0.5">
            <span className="h-1 w-1 animate-bounce rounded-full bg-muted-foreground [animation-delay:-0.2s]" />
            <span className="h-1 w-1 animate-bounce rounded-full bg-muted-foreground [animation-delay:0s]" />
            <span className="h-1 w-1 animate-bounce rounded-full bg-muted-foreground [animation-delay:0.2s]" />
          </span>
        </button>
      </section>

      {/* Marketing sections */}
      <section id="discover" className="relative w-full border-t border-border/60 bg-[#0b0f18] text-white dark:bg-background dark:text-foreground">
        <div className="mx-auto max-w-7xl px-4">
          {/* Vision pipeline from reference */}
          <VisionPipeline />

          {/* Removed the old 3-step how-it-works cards per request */}

          {/* How it works (auto video playback) */}
          <div className="py-8 md:py-12">
            <HeroVideoSection />
          </div>

          {/* Features & Use cases (reference sections) */}
          <div className="py-8 md:py-12">
            <FeatureSection />
          </div>
          <div className="py-8 md:py-12">
            <UseCasesSection />
          </div>

          {/* Founder’s words using quote section */}
          <div className="py-8 md:py-12">
            <QuoteSection />
          </div>

          {/* FAQ */}
          <div className="py-8 md:py-16">
            <FAQSection />
          </div>

          {/* Footer links */}
          <div className="flex items-center justify-center gap-4 py-10 text-xs text-muted-foreground">
            <Link href="/legal?tab=terms" className="hover:underline">Terms</Link>
            <span>•</span>
            <Link href="/legal?tab=privacy" className="hover:underline">Privacy</Link>
          </div>
        </div>
      </section>
    </div>
  );
}

function PublicDashboard() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <PublicDashboardContent />
    </Suspense>
  );
}

export default function HomePage() {
  return <PublicDashboard />;
}
