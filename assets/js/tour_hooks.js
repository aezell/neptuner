// Tour and tutorial JavaScript hooks for Neptuner

export const FeatureHighlight = {
  mounted() {
    this.targetSelector = this.el.dataset.target;
    this.position = this.el.dataset.position || 'bottom';
    this.updatePosition();
    
    // Listen for window resize
    this.resizeHandler = () => this.updatePosition();
    window.addEventListener('resize', this.resizeHandler);
    
    // Listen for scroll
    this.scrollHandler = () => this.updatePosition();
    window.addEventListener('scroll', this.scrollHandler, true);
  },

  destroyed() {
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler);
    }
    if (this.scrollHandler) {
      window.removeEventListener('scroll', this.scrollHandler, true);
    }
  },

  updatePosition() {
    const target = document.querySelector(this.targetSelector);
    if (!target) return;

    const targetRect = target.getBoundingClientRect();
    const tooltipRect = this.el.getBoundingClientRect();
    
    let top, left;

    switch (this.position) {
      case 'top':
        top = targetRect.top - tooltipRect.height - 10;
        left = targetRect.left + (targetRect.width / 2) - (tooltipRect.width / 2);
        break;
      case 'bottom':
        top = targetRect.bottom + 10;
        left = targetRect.left + (targetRect.width / 2) - (tooltipRect.width / 2);
        break;
      case 'left':
        top = targetRect.top + (targetRect.height / 2) - (tooltipRect.height / 2);
        left = targetRect.left - tooltipRect.width - 10;
        break;
      case 'right':
        top = targetRect.top + (targetRect.height / 2) - (tooltipRect.height / 2);
        left = targetRect.right + 10;
        break;
    }

    // Keep tooltip within viewport
    const viewport = {
      width: window.innerWidth,
      height: window.innerHeight
    };

    left = Math.max(10, Math.min(left, viewport.width - tooltipRect.width - 10));
    top = Math.max(10, Math.min(top, viewport.height - tooltipRect.height - 10));

    this.el.style.top = `${top + window.scrollY}px`;
    this.el.style.left = `${left + window.scrollX}px`;

    // Highlight the target element
    this.highlightTarget(target);
  },

  highlightTarget(target) {
    // Remove existing highlights
    document.querySelectorAll('.tour-highlight').forEach(el => {
      el.classList.remove('tour-highlight');
    });

    // Add highlight to current target
    target.classList.add('tour-highlight');
    
    // Add CSS for highlight if not already present
    if (!document.getElementById('tour-highlight-styles')) {
      const style = document.createElement('style');
      style.id = 'tour-highlight-styles';
      style.textContent = `
        .tour-highlight {
          position: relative;
          z-index: 35;
          box-shadow: 0 0 0 4px rgba(147, 51, 234, 0.3), 0 0 0 8px rgba(147, 51, 234, 0.1);
          border-radius: 4px;
        }
      `;
      document.head.appendChild(style);
    }
  }
};

export const Hotspot = {
  mounted() {
    this.targetSelector = this.el.dataset.target;
    this.updatePosition();
    
    // Listen for window resize and scroll
    this.resizeHandler = () => this.updatePosition();
    this.scrollHandler = () => this.updatePosition();
    
    window.addEventListener('resize', this.resizeHandler);
    window.addEventListener('scroll', this.scrollHandler, true);
  },

  destroyed() {
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler);
    }
    if (this.scrollHandler) {
      window.removeEventListener('scroll', this.scrollHandler, true);
    }
  },

  updatePosition() {
    const target = document.querySelector(this.targetSelector);
    if (!target) return;

    const targetRect = target.getBoundingClientRect();
    const hotspotRect = this.el.getBoundingClientRect();
    
    // Center the hotspot on the target
    const top = targetRect.top + (targetRect.height / 2) - (hotspotRect.height / 2);
    const left = targetRect.left + (targetRect.width / 2) - (hotspotRect.width / 2);

    this.el.style.top = `${top + window.scrollY}px`;
    this.el.style.left = `${left + window.scrollX}px`;
  }
};

export const DashboardTour = {
  mounted() {
    this.currentStep = 1;
    this.totalSteps = 6;
    this.isActive = false;
    
    // Tour steps configuration
    this.tourSteps = [
      {
        target: '[data-tour="cosmic-perspective"]',
        title: 'Daily Cosmic Perspective',
        content: 'Your daily dose of existential clarity about productivity theater.',
        position: 'bottom'
      },
      {
        target: '[data-tour="statistics"]',
        title: 'Productivity Metrics',
        content: 'Track your cosmic productivity across tasks, habits, and achievements.',
        position: 'bottom'
      },
      {
        target: '[data-tour="quick-actions"]',
        title: 'Quick Actions',
        content: 'Rapidly create new tasks, habits, or navigate to key features.',
        position: 'left'
      },
      {
        target: '[data-tour="recent-activity"]',
        title: 'Recent Activity',
        content: 'See your latest accomplishments and cosmic productivity updates.',
        position: 'right'
      },
      {
        target: '[data-tour="connections"]',
        title: 'Service Connections',
        content: 'Monitor your connected services and sync status for deeper insights.',
        position: 'top'
      },
      {
        target: '[data-tour="navigation"]',
        title: 'Navigation',
        content: 'Explore tasks, habits, calendar, and achievements from the main menu.',
        position: 'bottom'
      }
    ];
  },

  startTour() {
    this.isActive = true;
    this.currentStep = 1;
    this.showStep(this.currentStep);
  },

  showStep(stepNumber) {
    const step = this.tourSteps[stepNumber - 1];
    if (!step) return;

    // Hide all existing highlights
    this.hideAllHighlights();

    // Show current step highlight
    this.pushEvent('show_tour_step', {
      step: stepNumber,
      total: this.totalSteps,
      target: step.target,
      title: step.title,
      content: step.content,
      position: step.position
    });
  },

  nextStep() {
    if (this.currentStep < this.totalSteps) {
      this.currentStep++;
      this.showStep(this.currentStep);
    } else {
      this.endTour();
    }
  },

  previousStep() {
    if (this.currentStep > 1) {
      this.currentStep--;
      this.showStep(this.currentStep);
    }
  },

  endTour() {
    this.isActive = false;
    this.hideAllHighlights();
    this.pushEvent('tour_completed', {});
  },

  hideAllHighlights() {
    document.querySelectorAll('.tour-highlight').forEach(el => {
      el.classList.remove('tour-highlight');
    });
  }
};

// Utility function to smoothly scroll to element
export function scrollToElement(selector, offset = 100) {
  const element = document.querySelector(selector);
  if (!element) return;

  const elementRect = element.getBoundingClientRect();
  const absoluteElementTop = elementRect.top + window.pageYOffset;
  const middle = absoluteElementTop - (window.innerHeight / 2) + offset;

  window.scrollTo({
    top: middle,
    behavior: 'smooth'
  });
}

// Feature introduction animations
export function highlightNewFeature(selector, duration = 3000) {
  const element = document.querySelector(selector);
  if (!element) return;

  element.style.animation = `pulse 1s ease-in-out 3`;
  
  setTimeout(() => {
    element.style.animation = '';
  }, duration);
}

// Progressive disclosure helpers
export function showFeatureGradually(features, delay = 1000) {
  features.forEach((selector, index) => {
    setTimeout(() => {
      const element = document.querySelector(selector);
      if (element) {
        element.style.opacity = '0';
        element.style.transform = 'translateY(20px)';
        element.style.transition = 'all 0.5s ease-out';
        
        setTimeout(() => {
          element.style.opacity = '1';
          element.style.transform = 'translateY(0)';
        }, 50);
      }
    }, index * delay);
  });
}