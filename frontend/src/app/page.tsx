'use client';

import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { SidebarProvider, SidebarInset } from '@/components/ui/sidebar';
import { SidebarLeft, FloatingMobileMenuButton } from '@/components/sidebar/sidebar-left';
import { Button } from '@/components/ui/button';
import { ChatInput } from '@/components/thread/chat-input/chat-input';
import { Examples } from '@/components/dashboard/examples';
import { cn } from '@/lib/utils';

// Shared key used by the real dashboard to auto-submit after login
const PENDING_PROMPT_KEY = 'pendingAgentPrompt';

function PublicDashboard() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [value, setValue] = useState('');
  const [redirecting, setRedirecting] = useState(false);
  const hasRedirectedRef = useRef(false);

  // Restore any draft when returning from auth cancellation
  useEffect(() => {
    const draft = localStorage.getItem(PENDING_PROMPT_KEY);
    if (draft) setValue(draft);
  }, []);

  // Prefetch auth and dashboard shell for fast handoff
  useEffect(() => {
    // Best effort: Next.js may no-op if not supported
    try {
      router.prefetch('/auth');
      router.prefetch('/dashboard');
    } catch {}
  }, [router]);

  const buildAuthUrl = useCallback((prompt: string | undefined) => {
    // Store full prompt locally (primary)
    const text = (prompt || '').trim();
    if (text) {
      try {
        localStorage.setItem(PENDING_PROMPT_KEY, text);
      } catch {}
      try {
        sessionStorage.setItem(PENDING_PROMPT_KEY, text);
      } catch {}
    }

    // Truncate for URL safety and avoid huge params
    const truncated = text.slice(0, 1000);
    const encoded = encodeURIComponent(truncated);
    const returnUrl = `/dashboard${encoded ? `?prefill=${encoded}` : ''}`;
    return `/auth?returnUrl=${encodeURIComponent(returnUrl)}`;
  }, []);

  const triggerAuthRedirect = useCallback((prompt?: string) => {
    if (hasRedirectedRef.current) return;
    hasRedirectedRef.current = true;
    setRedirecting(true);
    const url = buildAuthUrl(prompt ?? value);
    // small delay to let UI show affordance
    setTimeout(() => {
      window.location.href = url;
    }, 50);
  }, [buildAuthUrl, value]);

  // Handle public typing: first keypress triggers auth and preserves text
  const handleChange = useCallback((next: string) => {
    setValue(next);
    if (!redirecting && !hasRedirectedRef.current) {
      triggerAuthRedirect(next);
    }
  }, [redirecting, triggerAuthRedirect]);

  const handleSubmit = useCallback(() => {
    triggerAuthRedirect(value);
  }, [triggerAuthRedirect, value]);

  // Also allow starter cards to trigger auth with preserved prompt
  const handleSelectPrompt = useCallback((q: string) => {
    setValue(q);
    triggerAuthRedirect(q);
  }, [triggerAuthRedirect]);

  // Handle drag/drop in public mode – nudge to sign in
  const onDropCapture = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    triggerAuthRedirect(value);
  }, [triggerAuthRedirect, value]);

  // Top-right sign in button should carry any draft
  const onSignInClick = useCallback(() => {
    const url = buildAuthUrl(value);
    window.location.href = url;
  }, [buildAuthUrl, value]);

  // SEO/meta friendly H1 (visually hidden)
  const H1 = (
    <h1 className="sr-only">Iris — Chat Dashboard</h1>
  );

  return (
    <div className="flex h-screen w-full overflow-hidden" onDropCapture={onDropCapture}>
      {H1}
      <SidebarProvider>
        <SidebarLeft />
        <SidebarInset>
          {/* Minimal top bar: places Sign in where avatar would be */}
          <div className="flex items-center justify-end px-4 py-3 border-b border-border bg-background/95">
            <Button onClick={onSignInClick} variant="default" className="h-8 px-3">
              Sign in
            </Button>
          </div>

          {/* Main content area mirrors dashboard hero */}
          <div className="flex-1 overflow-y-auto">
            <div className="min-h-full flex flex-col">
              <div className="flex-1 flex items-center justify-center px-4 py-8">
                <div className="w-full max-w-[650px] flex flex-col items-center justify-center space-y-4 md:space-y-6">
                  <div className="flex flex-col items-center text-center w-full">
                    <p className="tracking-tight text-2xl md:text-3xl font-normal text-foreground/90">
                      What would you like to do today?
                    </p>
                  </div>
                  <div className="w-full">
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
                  </div>
                  <div className="w-full">
                    <Examples onSelectPrompt={handleSelectPrompt} count={4} />
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Minimal footer */}
          <div className="w-full px-4 py-6 border-t border-border text-xs text-muted-foreground">
            <div className="max-w-7xl mx-auto flex items-center justify-center gap-4">
              <a href="/legal?tab=terms" className="hover:underline">Terms</a>
              <span>•</span>
              <a href="/legal?tab=privacy" className="hover:underline">Privacy</a>
            </div>
          </div>

          {/* Floating mobile menu button for parity */}
          <FloatingMobileMenuButton />
        </SidebarInset>
      </SidebarProvider>
    </div>
  );
}

export default function HomePage() {
  return <PublicDashboard />;
}
