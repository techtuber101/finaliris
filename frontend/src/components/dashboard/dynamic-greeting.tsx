'use client';

import { useAuth } from '@/components/AuthProvider';
import { useMemo } from 'react';

interface DynamicGreetingProps {
  className?: string;
}

export function DynamicGreeting({ className }: DynamicGreetingProps) {
  const { user } = useAuth();

  const greeting = useMemo(() => {
    if (!user) return "What would you like to do today?";

    // Extract first name from user metadata or email
    const firstName = user.user_metadata?.name?.split(' ')[0] || 
                     user.user_metadata?.first_name ||
                     user.email?.split('@')[0] || 
                     'there';

    // Array of greeting templates
    const greetingTemplates = [
      // Time-based greetings with name
      { template: "Good morning, {name}!", timeRange: [6, 12] },
      { template: "Good afternoon, {name}!", timeRange: [12, 17] },
      { template: "Good evening, {name}!", timeRange: [17, 22] },
      { template: "Good night, {name}!", timeRange: [22, 6] },
      
      // Casual greetings with name
      { template: "Hey {name}, what's on your mind?", timeRange: null },
      { template: "Hi {name}! Ready to get things done?", timeRange: null },
      { template: "Hello {name}, how can I help today?", timeRange: null },
      { template: "What's up, {name}?", timeRange: null },
      
      // Generic greetings without name
      { template: "What would you like to do today?", timeRange: null },
      { template: "Ready when you are.", timeRange: null },
      { template: "I'm ready, are you?", timeRange: null },
      { template: "Let's get started.", timeRange: null },
      { template: "What can I help you with?", timeRange: null },
      { template: "How can I assist you today?", timeRange: null },
      { template: "What's the plan?", timeRange: null },
      { template: "Ready to tackle something new?", timeRange: null },
    ];

    // Get current hour for time-based greetings
    const currentHour = new Date().getHours();

    // Filter greetings based on time (if timeRange is specified)
    const availableGreetings = greetingTemplates.filter(template => {
      if (!template.timeRange) return true; // Always available
      
      const [start, end] = template.timeRange;
      if (start <= end) {
        return currentHour >= start && currentHour < end;
      } else {
        // Handle overnight ranges (e.g., 22-6)
        return currentHour >= start || currentHour < end;
      }
    });

    // Randomly select a greeting
    const selectedTemplate = availableGreetings[Math.floor(Math.random() * availableGreetings.length)];
    
    // Replace {name} placeholder with actual first name
    return selectedTemplate.template.replace('{name}', firstName);
  }, [user]);

  return (
    <p className={className}>
      {greeting}
    </p>
  );
}
