// Add floating button to return to merox.dev
(function() {
    'use strict';
    
    // Wait for DOM to be ready
    function initMeroxButton() {
        // Check if button already exists
        if (document.getElementById('merox-home-button')) {
            return;
        }
        
        // Create the button element
        const button = document.createElement('a');
        button.id = 'merox-home-button';
        button.href = 'https://merox.dev';
        button.target = '_blank';
        button.rel = 'noopener noreferrer';
        button.setAttribute('aria-label', 'Go to merox.dev');
        
        // Add icon and text
        button.innerHTML = `
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                <polyline points="9 22 9 12 15 12 15 22"></polyline>
            </svg>
            <span>Back to merox.dev</span>
        `;
        
        // Append to body
        document.body.appendChild(button);
    }
    
    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initMeroxButton);
    } else {
        initMeroxButton();
    }
    
    // Also try after a short delay to ensure page is fully loaded
    setTimeout(initMeroxButton, 500);
})();

  
