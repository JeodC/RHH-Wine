async function loadcask() {
    const container = document.getElementById('bottle-container');
    const countDisplay = document.getElementById('bottle-count');
    const searchBar = document.getElementById('search-bar');
    const genreDropdown = document.getElementById('genre-filter');
    const availabilityDropdown = document.getElementById('availability-filter');
    const sortDropdown = document.getElementById('sort-select');
    const GITHUB_REPO_BASE = 'https://github.com/JeodC/RHH-Wine/tree/main/';

    try {
        const res = await fetch('winecask.json');
        if (!res.ok) throw new Error('Failed to load winecask.json');
        const cask = await res.json();

        if (!cask.length) {
            container.textContent = 'No cask found.';
            return;
        }

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
        // Sorting Function
        // ------------------------------
        const sortcask = (list, method) => method === 'most_recent'
            ? [...list].sort((a,b) => new Date(b.source?.date_updated) - new Date(a.source?.date_updated))
            : [...list].sort((a,b) => (a.attr?.title || '').localeCompare(b.attr?.title || ''));

        // ------------------------------
        // Render Function
        // ------------------------------
        const rendercask = (filtered) => {
            const genreVal = genreDropdown.value;
            const availabilityVal = availabilityDropdown.value;

            let countText = `${filtered.length} released bottles`;
            if (genreVal !== 'all') countText += ` in genre "${genreDropdown.selectedOptions[0].text}"`;
            if (availabilityVal !== 'all') countText += ` with availability "${availabilityDropdown.selectedOptions[0].text}"`;
            countDisplay.textContent = countText;

            container.innerHTML = filtered.map(bottle => {
                const title = bottle.attr.title || bottle.name;
                const desc = bottle.attr.desc || '';
                const screenshot = bottle.source.screenshot_url || '';
                const detailsHref = bottle.source.readme_url || '';

                // Use last folder of download_url as filename
                let downloadFolderName = 'download';
                if (bottle.source.download_url) {
                    downloadFolderName = bottle.source.download_url.replace(/\/+$/, '').split('/').pop();
                }
                const downloadHref = bottle.source.download_url;

                const reqs = (bottle.attr?.reqs || []).join(', ');
                const genres = (bottle.attr?.genres || []).join(', ');

                return `
                    <div class="bottle-card">
                        <img src="${screenshot}" alt="${title} screenshot">
                        <div class="bottle-info">
                            <h2 class="bottle-title">${title}</h2>
                            <p class="bottle-desc">${desc}</p>
                            <div class="bottle-footer">
                                ${genres ? `<div class="bottle-genres">${genres}</div>` : ''}
                                <div class="bottle-buttons">
                                    <a class="details-link" href="${detailsHref}" target="_blank" rel="noopener noreferrer">Details</a>
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