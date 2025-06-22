// A global variable to store the URL of the last right-clicked link.
let lastClickedLinkURL = null;

// Listen for right-clicks to remember which link the user is interacting with.
window.addEventListener('contextmenu', function(event) {
    let targetElement = event.target.closest('a');
    if (targetElement && targetElement.href) {
        lastClickedLinkURL = new URL(targetElement.href, document.baseURI).href;
    } else {
        lastClickedLinkURL = null;
    }
}, true);

// Listen for commands from the Swift code.
safari.self.addEventListener("message", messageHandler);

function messageHandler(event) {
    // Handler for the "Save Link" command
    if (event.name === "saveLinkViaJavaScript") {
        setTimeout(function() {
            if (!lastClickedLinkURL) {
                console.error("Wallabag Error: No valid link was found.");
                return;
            }
            saveUrlToWallabag(lastClickedLinkURL, event.message.token, event.message.serverURL);
        }, 100);
    }
    
    // Handler for the "Save All Links" command
    if (event.name === "saveAllLinksViaJavaScript") {
        const token = event.message.token;
        const serverURL = event.message.serverURL;

        if (!token || !serverURL) { return; }

        const linksToSave = [];
        document.querySelectorAll('a[href]').forEach(function(a) {
            const absoluteUrl = new URL(a.href, document.baseURI).href;
            if (absoluteUrl.startsWith('http')) {
                 linksToSave.push(absoluteUrl);
            }
        });

        if (linksToSave.length === 0) { return; }

        // Save all links and show a final confirmation alert.
        const savePromises = linksToSave.map(url => saveUrlToWallabag(url, token, serverURL, true));
        Promise.all(savePromises).then(results => {
            const successfulSaves = results.filter(success => success).length;
            alert(`Finished! Successfully saved ${successfulSaves} out of ${linksToSave.length} links.`);
        });
    }
}

// Reusable function to save a single URL to Wallabag.
function saveUrlToWallabag(urlToSave, token, serverURL, silentMode = false) {
    return fetch(serverURL + "/api/entries.json", {
        method: 'POST',
        headers: {
            'Authorization': 'Bearer ' + token,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ 'url': urlToSave })
    })
    .then(response => {
        if (!response.ok && !silentMode) {
            alert(`Wallabag Error: Failed to save ${urlToSave}. Server responded with status: ${response.status}`);
        }
        return response.ok;
    })
    .catch(error => {
        if (!silentMode) {
            alert(`Wallabag Network Error: Could not connect to the server for ${urlToSave}.\n\n${error}`);
        }
        return false;
    });
}
