async function loadcask() {
    const container = document.getElementById('bottle-container');
    const countDisplay = document.getElementById('bottle-count');
    const searchBar = document.getElementById('search-bar');
    const genreDropdown = document.getElementById('genre-filter');
    const availabilityDropdown = document.getElementById('availability-filter');
    const sortDropdown = document.getElementById('sort-select');
    const GITHUB_REPO_OWNER = 'JeodC';
    const GITHUB_REPO_NAME = 'RHH-Wine';

    try {
        // ------------------------------
        // Load winecask.json
        // ------------------------------
        const res = await fetch('winecask.json');
        if (!res.ok) throw new Error('Failed to load winecask.json');
        const cask = await res.json();

        if (!cask.length) {
            container.textContent = 'No cask found.';
            return;
        }

        // ------------------------------
        // Fetch GitHub releases for download counts
        // ------------------------------
        const apiRes = await fetch(`https://api.github.com/repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/releases`);
        if (!apiRes.ok) throw new Error('Failed to fetch GitHub releases');
        const releases = await apiRes.json();

        // Map asset download counts by filename
        const downloadCounts = {};
        releases.forEach(release => {
            release.assets.forEach(asset => {
                downloadCounts[asset.name] = asset.download_count;
            });
        });

        // ------------------------------
        // Helper to populate dropdowns
        // ------------------------------
        const populateDropdown = (dropdown, values, mapFn = v => v) => {
            values.forEach(v => {
                const opt = document.createElement('option');
                opt.value = v;
                opt.textContent = mapFn(v);
                dropdown.appendChild(opt);
            });
        };

        // ------------------------------
        // Populate Genre Dropdown
        // ------------------------------
        const genreSet = new Set(cask.flatMap(p => p.attr?.genres || []));
        populateDropdown(genreDropdown, Array.from(genreSet).sort(), g => g.charAt(0).toUpperCase() + g.slice(1));

        // ------------------------------
        // Populate Availability Dropdown
        // ------------------------------
        const availabilitySet = new Set(cask.map(p => p.attr?.availability).filter(Boolean));
        populateDropdown(availabilityDropdown, Array.from(availabilitySet).sort(), a =>
            ({ full: 'Ready to run', demo: 'Demo files included', free: 'Free, files needed' }[a.toLowerCase()] || a)
        );

        // ------------------------------
        // Add "Most Downloaded" option to sort dropdown if missing
        // ------------------------------
        if (![...sortDropdown.options].some(o => o.value === 'most_downloaded')) {
            const opt = document.createElement('option');
            opt.value = 'most_downloaded';
            opt.textContent = 'Most Downloaded';
            sortDropdown.appendChild(opt);
        }

        // ------------------------------
        // Sorting Function
        // ------------------------------
        const sortcask = (list, method) => {
            if (method === 'most_recent') {
                return [...list].sort((a,b) => new Date(b.source?.date_updated) - new Date(a.source?.date_updated));
            } else if (method === 'most_downloaded') {
                return [...list].sort((a,b) => {
                    const fileA = a.source.download_url ? a.source.download_url.split('/').pop() : '';
                    const fileB = b.source.download_url ? b.source.download_url.split('/').pop() : '';
                    const countA = downloadCounts[fileA] || 0;
                    const countB = downloadCounts[fileB] || 0;
                    return countB - countA;
                });
            } else {
                return [...list].sort((a,b) => (a.attr?.title || '').localeCompare(b.attr?.title || ''));
            }
        };

        // ------------------------------
        // Render Function
        // ------------------------------
        const rendercask = (filtered) => {
            const genreVal = genreDropdown.value;
            const availabilityVal = availabilityDropdown.value;

            let countText = `${filtered.length} released bottles`;
            if (genreVal !== 'all') countText += ` in "${genreDropdown.selectedOptions[0].text}"`;
            countDisplay.textContent = countText;

            container.innerHTML = filtered.map(bottle => {
                const title = bottle.attr.title || bottle.name;
                const screenshot = bottle.source.screenshot_url || '';
                const downloadHref = bottle.source.download_url || '';
                const filename = downloadHref ? downloadHref.split('/').pop() : '';
                const downloadCount = downloadCounts[filename] || 0;
                const genres = (bottle.attr?.genres || []).join(', ');
                const lastCommit = bottle.source.last_commit;
                const displayCommit = (!lastCommit || lastCommit.includes('Update winecask.json')) 
                    ? "" 
                    : lastCommit;

                return `
                    <div class="bottle-card">
                        <img src="${screenshot}" alt="${title} screenshot" loading="lazy">
                        <div class="bottle-info">
                            <h2 class="bottle-title">${title}</h2>
                            <p class="bottle-desc">${bottle.attr.desc || ''}</p>
                            <div class="bottle-footer">
                                <p class="download-count"><strong>Downloads since last update:</strong> ${downloadCount}</p>
                                ${genres ? `<div class="bottle-genres">${genres}</div>` : ''}
                                ${displayCommit ? `<div class="bottle-commit-banner" title="${displayCommit}">${displayCommit}</div>` : ''}
                                <div class="bottle-buttons">
                                    <a class="details-link" href="${bottle.source.readme_url || ''}" target="_blank" rel="noopener noreferrer">Details</a>
                                    <a class="download-link" href="${downloadHref}" target="_blank" rel="noopener noreferrer">Download</a>
                                </div>
                            </div>
                        </div>
                    </div>`;
            }).join('');
        };

        // ------------------------------
        // Filter + Display Update
        // ------------------------------
        const updateDisplay = () => {
            const genre = genreDropdown.value;
            const availability = availabilityDropdown.value;
            const query = searchBar.value.trim().toLowerCase();

            const filtered = cask.filter(p => {
                if (genre !== 'all' && !p.attr?.genres?.includes(genre)) return false;
                if (availability !== 'all' && p.attr?.availability !== availability) return false;
                if (query && !(p.attr.title || '').toLowerCase().includes(query)) return false;
                return true;
            });

            rendercask(sortcask(filtered, sortDropdown.value));
        };

        // Initial render
        updateDisplay();

        // Event listeners
        [searchBar, genreDropdown, availabilityDropdown, sortDropdown]
            .forEach(el => el.addEventListener('input', updateDisplay));

    } catch(err) {
        container.textContent = 'Error loading bottles: ' + err.message;
    }
}

loadcask();