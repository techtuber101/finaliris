"use client";

import { useEffect } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { createClient } from "@/lib/supabase/client";
import { projectKeys } from "./keys";

/**
 * Subscribes to Supabase realtime updates on the `projects` table for the current user
 * and invalidates the React Query caches so UI reflects background renames immediately.
 */
export function useProjectsRealtime() {
  const queryClient = useQueryClient();

  useEffect(() => {
    const supabase = createClient();

    let isMounted = true;
    let channel: ReturnType<typeof supabase.channel> | null = null;

    const setup = async () => {
      try {
        const { data: userData, error } = await supabase.auth.getUser();
        const userId = !error && userData?.user ? userData.user.id : undefined;
        const channelName = userId ? `projects-owner-${userId}` : 'projects-public';
        const filter = userId ? `account_id=eq.${userId}` : 'is_public=eq.true';

        // Subscribe to updates for user-owned (or public if no user) projects
        const ch = supabase
          .channel(channelName)
          .on(
            'postgres_changes',
            {
              event: '*',
              schema: 'public',
              table: 'projects',
              filter,
            },
            (payload) => {
              // Invalidate lists and the specific project details on any change
              const projectId = (payload.new as any)?.project_id || (payload.old as any)?.project_id;
              queryClient.invalidateQueries({ queryKey: projectKeys.lists() });
              if (projectId) {
                queryClient.invalidateQueries({ queryKey: projectKeys.details(projectId) });
              }

              // If name changed, dispatch a browser event so UI can animate the change
              try {
                const oldName = (payload.old as any)?.name;
                const newName = (payload.new as any)?.name;
                if (
                  typeof window !== 'undefined' &&
                  projectId && newName && oldName !== newName
                ) {
                  window.dispatchEvent(
                    new CustomEvent('project-renamed', {
                      detail: { projectId, oldName, newName },
                    })
                  );
                }
              } catch (_) {
                // no-op
              }
            }
          )
          .subscribe();

        if (isMounted) {
          channel = ch;
        } else {
          // If unmounted during async setup, immediately remove channel
          supabase.removeChannel(ch);
        }
      } catch (_) {
        // Best-effort: ignore realtime setup errors
      }
    };

    setup();

    return () => {
      isMounted = false;
      if (channel) {
        const supa = createClient();
        supa.removeChannel(channel);
        channel = null;
      }
    };
  }, [queryClient]);
}
