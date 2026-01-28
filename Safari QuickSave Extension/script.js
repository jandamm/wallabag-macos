// A global variable to store the URL of the last right-clicked link.
let lastClickedLinkURL = null;

window.addEventListener('contextmenu', function(event) {
    let targetElement = event.target.closest('a');
    if (targetElement && targetElement.href) {
        lastClickedLinkURL = new URL(targetElement.href, document.baseURI).href;
    } else {
        lastClickedLinkURL = null;
    }
}, true);

safari.self.addEventListener("message", messageHandler);

function messageHandler(event) {
    switch(event.name) {
        case "getLinkedURL":
            safari.extension.dispatchMessage(event.message.callbackId, {
                url: lastClickedLinkURL.toString()
            });
            break;

        case "showLinkSelectorUI":
            showLinkSelector(event.message.callbackId);
            break;

        default:
            console.error("❌ Unknown Message:", event.name);
    }
}

// The UI logic with updated, more robust CSS.
function showLinkSelector(callbackId) {
    const allLinks = [];
    document.querySelectorAll('a[href]').forEach(function(a) {
        const absoluteUrl = new URL(a.href, document.baseURI).href;
        if (absoluteUrl.startsWith('http')) {
            allLinks.push({ url: absoluteUrl, title: a.innerText.trim() || a.href });
        }
    });

    if (allLinks.length === 0) {
        alert("No links found on this page.");
        return;
    }

    const modal = document.createElement('div');
    modal.id = 'wallabag-selector-modal';
    modal.innerHTML = `
        <div class="wallabag-modal-content">
            <header>
                <h1>Select Links to Save (${allLinks.length} found)</h1>
                <button id="wallabag-close-btn">&times;</button>
            </header>
            <div class="wallabag-controls">
                <input type="text" id="wallabag-filter" placeholder="Filter by regex (e.g., *.pdf or -*.jpg)">
                <button id="wallabag-select-all">Select All Visible</button>
                <button id="wallabag-select-none">Select None Visible</button>
            </div>
            <ul id="wallabag-links-list">
                ${allLinks.map((link, index) => `
                    <li class="wallabag-link-item" data-index="${index}">
                        <input type="checkbox" id="wallabag-link-${index}" checked>
                        <label for="wallabag-link-${index}">
                            <span class="title">${link.title}</span>
                            <span class="url">${link.url}</span>
                        </label>
                    </li>
                `).join('')}
            </ul>
            <footer>
                <button id="wallabag-save-btn">Save Selected Links</button>
                <p id="wallabag-counter">0 links selected</p>
            </footer>
        </div>
        <style>
            /* --- THIS CSS IS NOW MORE ROBUST --- */
            #wallabag-selector-modal { all: initial; /* CSS Reset */ position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 2147483647; display: flex; align-items: center; justify-content: center; font-family: -apple-system, sans-serif; font-size: 14px; }
            #wallabag-selector-modal .wallabag-modal-content { all: initial; background: #fff; border-radius: 8px; width: 80%; max-width: 700px; height: 80vh; display: flex; flex-direction: column; box-shadow: 0 5px 15px rgba(0,0,0,0.3); }
            #wallabag-selector-modal header, #wallabag-selector-modal footer, #wallabag-selector-modal .wallabag-controls { all: initial; display: flex; padding: 15px; border-bottom: 1px solid #ddd; align-items: center; }
            #wallabag-selector-modal header { justify-content: space-between; }
            #wallabag-selector-modal footer { border-bottom: 0; border-top: 1px solid #ddd; }
            #wallabag-selector-modal h1 { all: initial; font-size: 18px; font-family: -apple-system, sans-serif; font-weight: bold; }
            #wallabag-selector-modal button { all: initial; font-family: -apple-system, sans-serif; font-size: 13px; padding: 6px 12px; border: 1px solid #ccc; border-radius: 5px; background-color: #f0f0f0; cursor: pointer; }
            #wallabag-selector-modal #wallabag-close-btn { all: initial; font-size: 24px; cursor: pointer; font-family: sans-serif; }
            #wallabag-selector-modal #wallabag-links-list { all: initial; display: block; list-style: none; overflow-y: auto; flex-grow: 1; }
            #wallabag-selector-modal .wallabag-link-item { all: initial; display: flex; padding: 10px 15px; border-bottom: 1px solid #eee; align-items: center; color: #000; }
            #wallabag-selector-modal .wallabag-link-item.hidden { display: none; }
            #wallabag-selector-modal .wallabag-link-item input { 
                all: initial; 
                margin-right: 10px; 
                -webkit-appearance: checkbox; 
            }
            #wallabag-selector-modal .wallabag-link-item label { all: initial; display: flex; flex-direction: column; overflow: hidden; font-family: -apple-system, sans-serif; }
            #wallabag-selector-modal .wallabag-link-item .title { all: initial; font-weight: bold; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: block; }
            #wallabag-selector-modal .wallabag-link-item .url { all: initial; font-size: 12px; color: #555; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: block; }
            #wallabag-selector-modal #wallabag-save-btn { background-color: #007aff; color: white; font-weight: bold; }
            #wallabag-selector-modal #wallabag-counter { all: initial; margin-left: auto; font-family: -apple-system, sans-serif; font-size: 13px; }
            #wallabag-selector-modal input[type="text"] { all: initial; flex-grow: 1; padding: 6px; border: 1px solid #ccc; border-radius: 4px; font-family: -apple-system, sans-serif; font-size: 13px; }
        </style>
    `;
    document.body.appendChild(modal);

    // --- The rest of the logic that wires up the UI is unchanged ---
    const filterInput = modal.querySelector('#wallabag-filter');
    const linksList = modal.querySelector('#wallabag-links-list');
    
    function updateCounter() {
        const count = modal.querySelectorAll('.wallabag-link-item:not(.hidden) input:checked').length;
        modal.querySelector('#wallabag-counter').textContent = `${count} link(s) selected`;
    }
    function applyFilter() {
        const filterText = filterInput.value;
        const isExclusion = filterText.startsWith('-');
        const regexText = isExclusion ? filterText.substring(1) : filterText;
        let regex;
        try { regex = new RegExp(regexText, 'i'); } catch (e) { return; }
        modal.querySelectorAll('.wallabag-link-item').forEach(item => {
            const link = allLinks[item.dataset.index];
            const textToMatch = `${link.title} ${link.url}`;
            const matches = regex.test(textToMatch);
            item.classList.toggle('hidden', isExclusion ? matches : !matches);
        });
        updateCounter();
    }
    
    filterInput.addEventListener('input', applyFilter);
    linksList.addEventListener('change', updateCounter);
    modal.querySelector('#wallabag-close-btn').addEventListener('click', () => modal.remove());
    modal.querySelector('#wallabag-select-all').addEventListener('click', () => {
        modal.querySelectorAll('.wallabag-link-item:not(.hidden) input').forEach(cb => cb.checked = true);
        updateCounter();
    });
    modal.querySelector('#wallabag-select-none').addEventListener('click', () => {
        modal.querySelectorAll('.wallabag-link-item:not(.hidden) input').forEach(cb => cb.checked = false);
        updateCounter();
    });
    modal.querySelector('#wallabag-save-btn').addEventListener('click', () => {
        const selectedLinks = [];
        modal.querySelectorAll('.wallabag-link-item:not(.hidden) input:checked').forEach(cb => {
            selectedLinks.push(allLinks[cb.parentElement.dataset.index].url);
        });
        if (selectedLinks.length === 0) { alert("No links are selected."); return; }
        modal.querySelector('#wallabag-save-btn').textContent = 'Saving...';
        modal.querySelector('#wallabag-save-btn').disabled = true;
       safari.extension.dispatchMessage(callbackId, {
           urls: selectedLinks
       });
       modal.remove();
    });
    updateCounter();
}
