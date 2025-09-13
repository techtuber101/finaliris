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
        if (error || !userData?.user) {
          return;
        }

        const userId = userData.user.id;

        // Subscribe to updates for projects owned by current user
        const ch = supabase
          .channel(`projects-owner-${userId}`)
          .on(
            'postgres_changes',
            {
              event: '*',
              schema: 'public',
              table: 'projects',
              filter: `account_id=eq.${userId}`,
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
                  oldName && newName && oldName !== newName
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
