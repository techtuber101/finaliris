import { Button } from '@/components/ui/button';
import { KortixProcessModal } from '@/components/sidebar/kortix-enterprise-modal';

export function CTACard() {
  return (
    <div className="rounded-xl bg-gradient-to-br from-green-50 to-green-200 dark:from-green-950/40 dark:to-green-900/40 shadow-sm border border-green-200/50 dark:border-green-800/50 p-4 transition-all">
      <div className="flex flex-col space-y-4">
        <div className="flex flex-col">
          <span className="text-sm font-medium text-foreground">
            Give Iris Feedback
          </span>
          <span className="text-xs text-muted-foreground mt-0.5">
            Get free Iris coins as a reward
          </span>
        </div>

        <div>
          <KortixProcessModal>
            <Button className="w-full">
              Give Feedback
            </Button>
          </KortixProcessModal>
        </div>

      </div>
    </div>
  );
}
