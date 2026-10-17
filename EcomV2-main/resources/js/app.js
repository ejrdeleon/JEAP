import './bootstrap';

document.addEventListener('DOMContentLoaded', () => {
    const motionOk = !window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    document.querySelectorAll('[data-quantity-control]').forEach((control) => {
        const input = control.querySelector('[data-quantity-input]');
        const decrease = control.querySelector('[data-quantity-decrease]');
        const increase = control.querySelector('[data-quantity-increase]');
        if (!input || !decrease || !increase) {
            return;
        }

        const updateButtons = () => {
            const minimum = Number(input.min) || 1;
            const maximum = Number(input.max) || Number.POSITIVE_INFINITY;
            const quantity = Number(input.value) || minimum;
            decrease.disabled = input.disabled || quantity <= minimum;
            increase.disabled = input.disabled || quantity >= maximum;
        };

        decrease.addEventListener('click', () => {
            input.value = String(Math.max(Number(input.min) || 1, (Number(input.value) || 1) - 1));
            input.dispatchEvent(new Event('change', { bubbles: true }));
            updateButtons();
        });
        increase.addEventListener('click', () => {
            const maximum = Number(input.max) || Number.POSITIVE_INFINITY;
            input.value = String(Math.min(maximum, (Number(input.value) || 1) + 1));
            input.dispatchEvent(new Event('change', { bubbles: true }));
            updateButtons();
        });
        input.addEventListener('input', updateButtons);
        updateButtons();
    });

    const showToast = (message) => {
        let toast = document.querySelector('.cart-toast');
        if (!toast) {
            toast = document.createElement('div');
            toast.className = 'cart-toast';
            toast.setAttribute('role', 'status');
            const mainContainer = document.querySelector('.cart-items-column')
                || document.querySelector('.s3-main')
                || document.body;
            mainContainer.prepend(toast);
        }
        toast.textContent = message;
        toast.style.display = 'block';
        toast.style.opacity = '1';
        clearTimeout(toast.__timer);
        toast.__timer = setTimeout(() => {
            toast.style.transition = 'opacity 0.3s ease';
            toast.style.opacity = '0';
            setTimeout(() => {
                if (toast.style.opacity === '0') {
                    toast.style.display = 'none';
                }
            }, 300);
        }, 2500);
    };

    const updateHeaderCartCounts = (count) => {
        if (typeof count === 'undefined') return;
        document.querySelectorAll('.cart-count').forEach((badge) => {
            badge.textContent = String(count);
        });
    };

    document.querySelectorAll('[data-cart-add-form]').forEach((form) => {
        form.addEventListener('submit', async (event) => {
            const input = form.querySelector('[name="quantity"]');
            const requested = Number(input?.value) || 1;
            const current = Number(form.dataset.existingQuantity) || 0;
            if (current + requested > 10
                && !window.confirm(`This will add more than 10 of this product to your cart. Continue?`)) {
                event.preventDefault();
                return;
            }

            event.preventDefault();
            const submitBtn = form.querySelector('button[type="submit"]');
            const originalBtnText = submitBtn?.textContent;
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.textContent = 'Adding...';
            }

            const token = document.querySelector('meta[name="csrf-token"]')?.content
                || form.querySelector('input[name="_token"]')?.value;
            const variantIdInput = form.querySelector('input[name="product_variant_id"]');

            try {
                const response = await fetch(form.action, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': token,
                        'X-Requested-With': 'XMLHttpRequest',
                    },
                    body: JSON.stringify({
                        product_variant_id: variantIdInput?.value,
                        quantity: requested,
                    }),
                });

                const data = await response.json();
                if (!response.ok || !data.success) {
                    throw new Error(data.message || 'Could not add to cart.');
                }

                updateHeaderCartCounts(data.cart_count);
                form.dataset.existingQuantity = String(data.item_quantity ?? (current + requested));
                showToast(data.message || 'Added to cart');
            } catch (err) {
                alert(err.message || 'Failed to add product to cart.');
            } finally {
                if (submitBtn) {
                    submitBtn.disabled = false;
                    submitBtn.textContent = originalBtnText;
                }
            }
        });
    });

    document.querySelectorAll('[data-cart-update-form]').forEach((form) => {
        const decreaseBtn = form.querySelector('[data-qty-btn="decrease"]') || form.querySelectorAll('button[name="quantity"]')[0];
        const increaseBtn = form.querySelector('[data-qty-btn="increase"]') || form.querySelectorAll('button[name="quantity"]')[1];
        const input = form.querySelector('[data-qty-input]') || form.querySelector('input[name="qty_display"]');
        const cartItem = form.closest('.cart-item');
        const lineTotalEl = cartItem?.querySelector('[data-cart-line-total]');
        const stockMsgContainer = cartItem?.querySelector('[data-cart-stock-container]');

        const handleQuantityChange = async (button, event) => {
            event.preventDefault();
            const requested = Number(button.value);
            if (requested > 10
                && !window.confirm('This will leave more than 10 of this product in your cart. Continue?')) {
                return;
            }

            const originalValue = input ? Number(input.value) : 1;
            const originalDecreaseVal = decreaseBtn?.value;
            const originalIncreaseVal = increaseBtn?.value;
            const originalDecreaseDisabled = decreaseBtn?.disabled;
            const originalIncreaseDisabled = increaseBtn?.disabled;

            if (input) input.value = String(requested);
            if (decreaseBtn) {
                decreaseBtn.value = String(Math.max(1, requested - 1));
                decreaseBtn.disabled = requested <= 1;
            }
            if (increaseBtn) {
                increaseBtn.value = String(requested + 1);
                const maxStock = Number(cartItem?.dataset.itemStock) || 999;
                increaseBtn.disabled = requested >= maxStock;
            }
            form.style.opacity = '0.6';
            form.style.pointerEvents = 'none';

            const token = document.querySelector('meta[name="csrf-token"]')?.content
                || form.querySelector('input[name="_token"]')?.value;

            try {
                const response = await fetch(form.action, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': token,
                        'X-Requested-With': 'XMLHttpRequest',
                    },
                    body: JSON.stringify({
                        _method: 'PATCH',
                        quantity: requested,
                    }),
                });

                const data = await response.json();

                if (!response.ok || !data.success) {
                    throw new Error(data.message || 'Unable to update cart quantity.');
                }

                if (input) input.value = String(data.item.quantity);
                if (decreaseBtn) {
                    decreaseBtn.value = String(Math.max(1, data.item.quantity - 1));
                    decreaseBtn.disabled = !data.item.can_decrease;
                }
                if (increaseBtn) {
                    increaseBtn.value = String(data.item.quantity + 1);
                    increaseBtn.disabled = !data.item.can_increase;
                }
                if (lineTotalEl) {
                    lineTotalEl.textContent = data.item.line_total_formatted;
                }

                if (stockMsgContainer) {
                    if (!data.item.has_stock) {
                        stockMsgContainer.innerHTML = `<p class="cart-stock is-unavailable">Only ${data.item.stock} available. Reduce the quantity to continue.</p>`;
                    } else {
                        stockMsgContainer.innerHTML = `<p class="cart-stock">In stock <span aria-hidden="true">·</span> ${data.item.stock} available</p>`;
                    }
                }

                document.querySelectorAll('[data-summary-total], [data-summary-subtotal]').forEach((el) => {
                    el.textContent = data.cart.total_formatted;
                });
                document.querySelectorAll('[data-summary-products-count]').forEach((el) => {
                    el.textContent = data.cart.products_label;
                });
                document.querySelectorAll('[data-cart-count-heading]').forEach((el) => {
                    el.textContent = `${data.cart.products_label} in your cart`;
                });

                const checkoutWrapper = document.querySelector('[data-checkout-btn-wrapper]');
                if (checkoutWrapper) {
                    if (data.cart.can_checkout) {
                        checkoutWrapper.innerHTML = `<a class="s3-btn" href="/checkout">Continue to checkout <span aria-hidden="true">→</span></a>`;
                    } else {
                        checkoutWrapper.innerHTML = `<p class="cart-checkout-blocked" role="status">Update or remove unavailable items to continue.</p>`;
                    }
                }

                updateHeaderCartCounts(data.cart.total_items_count);

                showToast(data.message || 'Cart updated');
            } catch (err) {
                if (input) input.value = String(originalValue);
                if (decreaseBtn) {
                    decreaseBtn.value = originalDecreaseVal;
                    decreaseBtn.disabled = originalDecreaseDisabled;
                }
                if (increaseBtn) {
                    increaseBtn.value = originalIncreaseVal;
                    increaseBtn.disabled = originalIncreaseDisabled;
                }
                alert(err.message || 'Failed to update cart. Please try again.');
            } finally {
                form.style.removeProperty('opacity');
                form.style.removeProperty('pointer-events');
            }
        };

        if (decreaseBtn) {
            decreaseBtn.addEventListener('click', (e) => handleQuantityChange(decreaseBtn, e));
        }
        if (increaseBtn) {
            increaseBtn.addEventListener('click', (e) => handleQuantityChange(increaseBtn, e));
        }
    });

    document.querySelectorAll('[data-cart-remove-form]').forEach((form) => {
        form.addEventListener('submit', async (event) => {
            event.preventDefault();
            const cartItem = form.closest('.cart-item');
            const token = document.querySelector('meta[name="csrf-token"]')?.content
                || form.querySelector('input[name="_token"]')?.value;

            try {
                if (cartItem) cartItem.style.opacity = '0.5';
                const response = await fetch(form.action, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': token,
                        'X-Requested-With': 'XMLHttpRequest',
                    },
                    body: JSON.stringify({
                        _method: 'DELETE',
                    }),
                });

                const data = await response.json();
                if (!response.ok || !data.success) {
                    throw new Error(data.message || 'Could not remove item.');
                }

                if (cartItem) cartItem.remove();
                updateHeaderCartCounts(data.cart.total_items_count);

                if (data.cart.is_empty) {
                    const col = document.querySelector('[data-cart-items-column]');
                    if (col) {
                        const heading = col.querySelector('.cart-page-heading');
                        col.innerHTML = '';
                        if (heading) col.appendChild(heading);
                        col.insertAdjacentHTML('beforeend', '<div class="cart-empty"><span class="cart-empty-icon" aria-hidden="true">🛒</span><h2>Your cart is empty</h2><p>Find something you love and it will be waiting here.</p><a href="/products">Browse products</a></div>');
                    }
                    const summaryContainer = document.querySelector('[data-cart-summary-container]');
                    if (summaryContainer) {
                        summaryContainer.innerHTML = '<p class="cart-summary-note">Your order total will appear here when you add products.</p>';
                    }
                } else {
                    document.querySelectorAll('[data-summary-total], [data-summary-subtotal]').forEach((el) => {
                        el.textContent = data.cart.total_formatted;
                    });
                    document.querySelectorAll('[data-summary-products-count]').forEach((el) => {
                        el.textContent = data.cart.products_label;
                    });
                    document.querySelectorAll('[data-cart-count-heading]').forEach((el) => {
                        el.textContent = `${data.cart.products_label} in your cart`;
                    });
                }

                showToast(data.message || 'Removed from cart');
            } catch (err) {
                if (cartItem) cartItem.style.removeProperty('opacity');
                alert(err.message || 'Failed to remove item. Please try again.');
            }
        });
    });

    const toggle = document.querySelector('[data-nav-toggle]');
    const nav = document.getElementById('site-nav');
    if (toggle && nav) {
        toggle.addEventListener('click', () => {
            const open = nav.classList.toggle('is-open');
            toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
            toggle.textContent = open ? 'Close' : 'Menu';
        });
    }

    const catRoot = document.querySelector('[data-cat-select]');
    if (catRoot) {
        const catBtn = catRoot.querySelector('[data-cat-toggle]');
        const catMenu = catRoot.querySelector('[data-cat-menu]');
        const catLabel = catRoot.querySelector('[data-cat-label]');
        const catInput = catRoot.querySelector('[data-cat-input]');
        const searchBar = catRoot.closest('.search-cat');

        const setCatOpen = (open) => {
            catRoot.classList.toggle('is-open', open);
            searchBar?.classList.toggle('is-picking', open);
            catBtn?.setAttribute('aria-expanded', open ? 'true' : 'false');
        };

        catBtn?.addEventListener('click', (event) => {
            event.preventDefault();
            setCatOpen(!catRoot.classList.contains('is-open'));
        });

        catMenu?.querySelectorAll('[data-value]').forEach((option) => {
            option.addEventListener('click', (event) => {
                event.preventDefault();
                event.stopPropagation();
                const value = option.getAttribute('data-value') ?? '';
                if (catInput) {
                    catInput.value = value;
                }
                if (catLabel) {
                    catLabel.textContent = option.textContent.trim();
                }
                catMenu.querySelectorAll('[data-value]').forEach((item) => item.classList.remove('is-active'));
                option.classList.add('is-active');
                setCatOpen(false);
                searchBar?.requestSubmit();
            });
        });

        document.addEventListener('click', (event) => {
            if (!catRoot.contains(event.target)) {
                setCatOpen(false);
            }
        });

        document.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') {
                setCatOpen(false);
            }
        });
    }

    const markReveal = (el, index = 0) => {
        el.classList.add('reveal');
        el.style.setProperty('--stagger', String(Math.min(index, 12)));
    };

    document.querySelectorAll('.cat-row, .product-grid, .s3-grid4, .s3-popgrid, .mid-banners, .s3-feats, .footer-perks, .s3-relgrid').forEach((group) => {
        [...group.children].forEach((child, index) => markReveal(child, index));
    });

    document.querySelectorAll('.section-head, .hero-grid, .s3-auth-form, .s3-gallery, .s3-promo, .s3-pcard, .s3-infocard, .s3-paycard, .s3-summary, .s3-sidebox, .s3-feat, .banner, .promo-side').forEach((el, index) => {
        if (!el.classList.contains('reveal')) {
            markReveal(el, index % 6);
        }
    });

    const revealNodes = document.querySelectorAll('.reveal');
    revealNodes.forEach((node) => {
        const box = node.getBoundingClientRect();
        if (box.top < window.innerHeight * 0.92) {
            node.classList.add('is-in');
        }
    });

    if (motionOk && 'IntersectionObserver' in window) {
        document.documentElement.classList.add('has-motion');
        const observer = new IntersectionObserver((entries) => {
            entries.forEach((entry) => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('is-in');
                    observer.unobserve(entry.target);
                }
            });
        }, { threshold: 0.12, rootMargin: '0px 0px -6% 0px' });
        revealNodes.forEach((node) => {
            if (!node.classList.contains('is-in')) {
                observer.observe(node);
            }
        });
    } else {
        revealNodes.forEach((node) => node.classList.add('is-in'));
    }

    const initializePhilippineLocationPicker = (picker) => {
        const form = picker.closest('form');
        const endpoint = picker.dataset.endpoint;
        const selectors = picker.querySelector('[data-location-selectors]');
        const manual = picker.querySelector('[data-location-manual]');
        const status = picker.querySelector('[data-location-status]');
        const useManualButton = picker.querySelector('[data-location-use-manual]');
        const useSelectorsButton = picker.querySelector('[data-location-use-selects]');
        const countrySelect = picker.querySelector('[data-country-select]');
        const countryName = picker.querySelector('[data-country-name]');
        const postalSelect = picker.querySelector('[data-postal-select]');
        const postalSelectWrapper = picker.querySelector('[data-postal-select-wrapper]');
        const postalManual = picker.querySelector('[data-postal-manual]');
        const postalManualWrapper = picker.querySelector('[data-postal-manual-wrapper]');
        const postalValue = picker.querySelector('[data-postal-value]');
        const levels = Object.fromEntries(
            [...picker.querySelectorAll('[data-location-level]')].map((select) => [select.dataset.locationLevel, select]),
        );
        const wrappers = Object.fromEntries(
            [...picker.querySelectorAll('[data-location-wrapper]')].map((wrapper) => [wrapper.dataset.locationWrapper, wrapper]),
        );
        const manualInputs = Object.fromEntries(
            [...picker.querySelectorAll('[data-location-manual-field]')].map((input) => [input.dataset.locationManualField, input]),
        );
        const hiddenNames = Object.fromEntries(
            [...picker.querySelectorAll('[data-location-name]')].map((input) => [input.dataset.locationName, input]),
        );
        const hiddenCodes = Object.fromEntries(
            [...picker.querySelectorAll('[data-location-code]')].map((input) => [input.dataset.locationCode, input]),
        );
        const initial = {
            region: { code: picker.dataset.initialRegionCode, name: picker.dataset.initialRegionName },
            province: { code: picker.dataset.initialProvinceCode, name: picker.dataset.initialProvinceName },
            city: { code: picker.dataset.initialCityCode, name: picker.dataset.initialCityName },
            barangay: { code: picker.dataset.initialBarangayCode, name: picker.dataset.initialBarangayName },
        };
        let catalogReady = false;
        let manualTouched = false;
        let loading = false;

        const setLoading = (isLoading) => {
            loading = isLoading;
            Object.values(levels).forEach((select) => {
                select.disabled = isLoading || selectors.hidden || select.options.length <= 1;
            });
        };

        const writeHidden = (type, code, name) => {
            if (hiddenCodes[type]) {
                hiddenCodes[type].value = code ?? '';
            }
            if (hiddenNames[type]) {
                hiddenNames[type].value = name ?? '';
            }
        };

        const clearLocation = (type) => writeHidden(type, '', '');

        const resetSelect = (select, label) => {
            if (!select) {
                return;
            }
            select.replaceChildren(new Option(label, ''));
            select.value = '';
            select.disabled = true;
        };

        const findLocation = (locations, preferred) => locations.find((location) => location.code === preferred.code)
            ?? locations.find((location) => location.name.localeCompare(preferred.name ?? '', undefined, { sensitivity: 'base' }) === 0);

        const loadLocations = async (level, query = {}) => {
            const url = new URL(endpoint.replace('LEVEL', level), window.location.origin);
            Object.entries(query).forEach(([key, value]) => url.searchParams.set(key, value));
            const response = await fetch(url, { headers: { Accept: 'application/json' } });
            const body = await response.json();
            if (!response.ok) {
                throw new Error(body.message || 'Official Philippine location lookup failed.');
            }
            if (!Array.isArray(body.locations)) {
                throw new Error('Official Philippine location lookup returned an invalid response.');
            }
            return body.locations;
        };

        const populate = async (select, level, query, preferred, label) => {
            resetSelect(select, label);
            const locations = await loadLocations(level, query);
            locations.forEach((location) => {
                const option = new Option(location.name, location.code);
                option.dataset.parentCode = location.parent_code ?? '';
                select.add(option);
            });
            select.disabled = loading || locations.length === 0;

            const selected = findLocation(locations, preferred);
            if (selected) {
                select.value = selected.code;
            }

            return { locations, selected };
        };

        const selectedOption = (select) => select?.selectedOptions[0]?.value
            ? select.selectedOptions[0]
            : null;

        const resetBelowRegion = (clearPostal = false) => {
            ['province', 'city', 'barangay'].forEach(clearLocation);
            resetSelect(levels.provinces, 'Select a province');
            resetSelect(levels.municipalities, 'Select a city or municipality');
            resetSelect(levels.barangays, 'Select a barangay');
            if (clearPostal && postalManual) {
                postalManual.value = '';
                postalValue.value = '';
            }
            if (wrappers.province) {
                wrappers.province.hidden = false;
            }
            if (wrappers.barangay) {
                wrappers.barangay.hidden = false;
            }
        };

        const resetBelowProvince = (clearPostal = false) => {
            ['city', 'barangay'].forEach(clearLocation);
            resetSelect(levels.municipalities, 'Select a city or municipality');
            resetSelect(levels.barangays, 'Select a barangay');
            if (clearPostal && postalManual) {
                postalManual.value = '';
                postalValue.value = '';
            }
            if (wrappers.barangay) {
                wrappers.barangay.hidden = false;
            }
        };

        const resetBelowCity = (clearPostal = false) => {
            clearLocation('barangay');
            resetSelect(levels.barangays, 'Select a barangay');
            if (clearPostal && postalManual) {
                postalManual.value = '';
            }
            resetSelect(postalSelect, 'Select a postal code');
            if (postalSelectWrapper) {
                postalSelectWrapper.hidden = true;
            }
            if (postalManualWrapper) {
                postalManualWrapper.hidden = false;
            }
            if (postalSelect) {
                postalSelect.disabled = true;
            }
            if (postalManual) {
                postalManual.disabled = false;
            }
            if (postalValue) {
                postalValue.value = postalManual?.value ?? '';
                postalValue.disabled = true;
            }
            if (wrappers.barangay) {
                wrappers.barangay.hidden = false;
            }
        };

        const currentPreferences = () => Object.fromEntries(
            Object.keys(initial).map((type) => [type, {
                code: hiddenCodes[type]?.value || initial[type].code,
                name: hiddenNames[type]?.value || initial[type].name,
            }]),
        );

        const loadBarangays = async (preferred = null) => {
            const city = selectedOption(levels.municipalities);
            resetBelowCity(!preferred);
            if (!city) {
                return;
            }
            writeHidden('city', city.value, city.textContent);
            const [barangayResult, postalResponse] = await Promise.allSettled([
                populate(
                    levels.barangays,
                    'barangays',
                    { city_code: city.value, parent_code: city.dataset.parentCode ?? '' },
                    preferred?.barangay ?? {},
                    'Select a barangay',
                ),
                loadLocations('postal-codes', { city_code: city.value }),
            ]);
            const { locations, selected } = barangayResult;
            const postalLocations = postalResponse.status === 'fulfilled' ? postalResponse.value : [];
            if (wrappers.barangay) {
                wrappers.barangay.hidden = locations.length === 0;
            }
            if (selected) {
                writeHidden('barangay', selected.code, selected.textContent);
            }
            postalLocations.forEach((location) => postalSelect.add(new Option(location.name, location.code)));
            if (postalLocations.length > 0) {
                const savedPostalCode = picker.dataset.initialPostalCode || postalManual?.value || '';
                const savedCodeAvailable = postalLocations.some((location) => location.code === savedPostalCode);
                postalSelect.add(new Option('Enter another postal code', '__manual__'));
                postalSelect.value = savedCodeAvailable ? savedPostalCode : '__manual__';
                postalSelect.disabled = loading;
                postalSelectWrapper.hidden = false;
                postalManualWrapper.hidden = savedCodeAvailable;
                postalManual.disabled = savedCodeAvailable;
                postalValue.value = savedCodeAvailable ? savedPostalCode : postalManual.value;
                postalValue.disabled = !savedCodeAvailable;
                if (savedCodeAvailable) {
                    postalManual.value = savedPostalCode;
                }
            }
        };

        const loadMunicipalities = async (query, preferred = null) => {
            const { selected } = await populate(
                levels.municipalities,
                'municipalities',
                query,
                preferred?.city ?? {},
                'Select a city or municipality',
            );
            if (selected) {
                await loadBarangays(preferred);
            }
        };

        const loadProvinces = async (preferred = null) => {
            const region = selectedOption(levels.regions);
            resetBelowRegion(!preferred);
            if (!region) {
                return;
            }
            writeHidden('region', region.value, region.textContent);
            const { locations, selected } = await populate(
                levels.provinces,
                'provinces',
                { region_code: region.value, parent_code: region.dataset.parentCode ?? '' },
                preferred?.province ?? {},
                'Select a province',
            );
            if (locations.length === 0) {
                if (wrappers.province) {
                    wrappers.province.hidden = true;
                }
                await loadMunicipalities({ region_code: region.value, parent_code: region.dataset.parentCode ?? '' }, preferred);
                return;
            }
            if (wrappers.province) {
                wrappers.province.hidden = false;
            }
            if (selected) {
                writeHidden('province', selected.code, selected.textContent);
                await loadMunicipalities({ province_code: selected.value, parent_code: selected.dataset.parentCode ?? '' }, preferred);
            }
        };

        const showManualFallback = (error) => {
            catalogReady = false;
            status.textContent = error instanceof Error
                ? error.message
                : 'Official Philippine location lookup is unavailable. Enter the location manually.';
            setMode(false);
        };

        const setMode = (useOfficialLocations, values = {}) => {
            useOfficialLocations = useOfficialLocations && countrySelect.value === 'PH';
            const wasUsingOfficialLocations = !selectors.hidden;
            selectors.hidden = !useOfficialLocations;
            manual.hidden = useOfficialLocations;
            Object.values(levels).forEach((select) => {
                select.required = useOfficialLocations && ['regions', 'municipalities'].includes(select.dataset.locationLevel);
                select.disabled = !useOfficialLocations || select.options.length <= 1 || loading;
            });
            Object.entries(manualInputs).forEach(([type, input]) => {
                input.disabled = useOfficialLocations;
                input.required = !useOfficialLocations && type === 'city';
                if (hiddenNames[type]) {
                    hiddenNames[type].disabled = !useOfficialLocations;
                }
            });
            Object.values(hiddenCodes).forEach((input) => { input.disabled = !useOfficialLocations; });
            countryName.disabled = false;
            postalValue.disabled = true;
            postalManual.disabled = false;
            if (!useOfficialLocations) {
                postalManualWrapper.hidden = false;
            }
            if (postalSelect && useOfficialLocations) {
                postalSelect.disabled = postalSelect.options.length <= 1 || loading;
            } else if (postalSelect) {
                postalSelect.disabled = true;
            }
            if (useManualButton) {
                useManualButton.hidden = !useOfficialLocations;
            }
            if (useSelectorsButton) {
                useSelectorsButton.hidden = !catalogReady || useOfficialLocations;
            }

            if (!useOfficialLocations) {
                Object.entries(manualInputs).forEach(([type, input]) => {
                    if (Object.hasOwn(values, type)) {
                        input.value = values[type] ?? '';
                    } else if (wasUsingOfficialLocations && hiddenNames[type]) {
                        input.value = hiddenNames[type].value;
                    }
                    if (hiddenNames[type]) {
                        hiddenNames[type].value = input.value;
                    }
                });
                postalValue.value = postalManual.value;
            } else if (!postalSelectWrapper.hidden && postalSelect.value !== '__manual__') {
                postalValue.value = postalSelect.value;
                postalValue.disabled = postalSelect.value === '';
                postalManual.disabled = postalSelect.value !== '';
            }
        };

        const loadCatalog = async (matchInitial = true) => {
            setLoading(true);
            try {
                const preferred = matchInitial ? currentPreferences() : null;
                const { selected } = await populate(
                    levels.regions,
                    'regions',
                    {},
                    preferred?.region ?? {},
                    'Select a region',
                );
                catalogReady = true;
                if (selected) {
                    writeHidden('region', selected.code, selected.textContent);
                    await loadProvinces(preferred);
                } else {
                    resetBelowRegion(true);
                }
                if (manualTouched) {
                    status.textContent = 'Official PSGC locations are available. You can continue with manual entry or choose the official list.';
                    setMode(false);
                    return;
                }
                status.textContent = 'Select the official PSGC region, province, city or municipality, and barangay.';
                setMode(true);
            } catch (error) {
                showManualFallback(error);
            } finally {
                setLoading(false);
            }
        };

        const loadCountries = async () => {
            const initialCountryCode = picker.dataset.initialCountryCode || 'PH';
            try {
                const countries = await loadLocations('countries');
                countrySelect.replaceChildren(new Option('Select a country', ''));
                countries.forEach((country) => countrySelect.add(new Option(country.name, country.code)));
                countrySelect.value = countries.some((country) => country.code === initialCountryCode)
                    ? initialCountryCode
                    : 'PH';
                countryName.value = countries.find((country) => country.code === countrySelect.value)?.name ?? 'Philippines';
            } catch {
                countrySelect.replaceChildren(new Option('Philippines', 'PH'));
                countrySelect.value = 'PH';
                countryName.value = 'Philippines';
                status.textContent = 'The country service is temporarily unavailable. Philippines is available as a fallback.';
            } finally {
                countrySelect.disabled = false;
            }

            if (countrySelect.value === 'PH') {
                await loadCatalog(true);
            } else {
                status.textContent = 'PSGC location lists are available for the Philippines. Enter other country locations manually.';
                setMode(false);
            }
        };

        countrySelect?.addEventListener('change', () => {
            countryName.value = countrySelect.selectedOptions[0]?.textContent ?? '';
            Object.keys(hiddenCodes).forEach((type) => { hiddenCodes[type].value = ''; });
            Object.keys(hiddenNames).forEach((type) => { hiddenNames[type].value = ''; });
            Object.values(manualInputs).forEach((input) => { input.value = ''; });
            postalManual.value = '';
            postalValue.value = '';
            if (countrySelect.value === 'PH') {
                loadCatalog(false);
            } else {
                status.textContent = 'PSGC location lists are available for the Philippines. Enter other country locations manually.';
                setMode(false);
            }
        });

        levels.regions?.addEventListener('change', () => {
            const region = selectedOption(levels.regions);
            if (region) {
                writeHidden('region', region.value, region.textContent);
                setLoading(true);
                loadProvinces().catch(showManualFallback).finally(() => setLoading(false));
            } else {
                clearLocation('region');
                resetBelowRegion(true);
            }
        });
        levels.provinces?.addEventListener('change', () => {
            const province = selectedOption(levels.provinces);
            if (!province) {
                clearLocation('province');
                resetBelowProvince(true);
                return;
            }
            writeHidden('province', province.value, province.textContent);
            resetBelowProvince(true);
            setLoading(true);
            loadMunicipalities({
                province_code: province.value,
                parent_code: province.dataset.parentCode ?? '',
            }).catch(showManualFallback).finally(() => setLoading(false));
        });
        levels.municipalities?.addEventListener('change', () => {
            const city = selectedOption(levels.municipalities);
            if (!city) {
                clearLocation('city');
                resetBelowCity(true);
                return;
            }
            writeHidden('city', city.value, city.textContent);
            setLoading(true);
            loadBarangays().catch(showManualFallback).finally(() => setLoading(false));
        });
        levels.barangays?.addEventListener('change', () => {
            const barangay = selectedOption(levels.barangays);
            writeHidden('barangay', barangay?.value ?? '', barangay?.textContent ?? '');
        });
        postalSelect?.addEventListener('change', () => {
            const usingManualPostal = postalSelect.value === '__manual__';
            postalManualWrapper.hidden = !usingManualPostal;
            postalManual.disabled = !usingManualPostal;
            postalValue.value = usingManualPostal ? postalManual.value : postalSelect.value;
            postalValue.disabled = usingManualPostal || postalSelect.value === '';
            if (usingManualPostal) {
                postalManual.focus();
            }
        });
        postalManual?.addEventListener('input', () => {
            postalValue.value = postalManual.value;
            postalValue.disabled = true;
        });

        Object.entries(manualInputs).forEach(([type, input]) => {
            input.addEventListener('input', () => {
                manualTouched = true;
                if (hiddenNames[type]) {
                    hiddenNames[type].value = input.value;
                }
                Object.keys(hiddenCodes).forEach((codeType) => { hiddenCodes[codeType].value = ''; });
            });
        });

        useManualButton?.addEventListener('click', () => {
            manualTouched = true;
            Object.keys(hiddenCodes).forEach((type) => { hiddenCodes[type].value = ''; });
            setMode(false);
        });
        useSelectorsButton?.addEventListener('click', () => {
            if (countrySelect.value !== 'PH') {
                return;
            }
            manualTouched = false;
            loadCatalog(true);
        });
        picker.addEventListener('jeap:manual-location', (event) => {
            manualTouched = true;
            Object.keys(hiddenCodes).forEach((type) => { hiddenCodes[type].value = ''; });
            if (event.detail?.country_code) {
                countrySelect.value = event.detail.country_code;
                countryName.value = event.detail.country || countrySelect.selectedOptions[0]?.textContent || '';
            }
            setMode(false, event.detail ?? {});
        });

        picker.addEventListener('jeap:load-saved-address', (event) => {
            const address = event.detail ?? {};
            Object.entries({
                region: ['region_code', 'region_name'],
                province: ['province_code', 'province_name'],
                city: ['city_code', 'city_name'],
                barangay: ['barangay_code', 'barangay_name'],
            }).forEach(([type, [codeKey, nameKey]]) => {
                writeHidden(type, address[codeKey] ?? '', address[nameKey] ?? '');
            });
            picker.dataset.initialCountryCode = address.country_code || 'PH';
            picker.dataset.initialCountryName = address.country_name || 'Philippines';
            picker.dataset.initialPostalCode = address.postal_code || '';
            countrySelect.value = picker.dataset.initialCountryCode;
            countryName.value = picker.dataset.initialCountryName;
            if (countrySelect.value === 'PH') {
                loadCatalog(true);
            } else {
                setMode(false);
            }
        });

        loadCountries();
    };

    document.querySelectorAll('[data-philippine-location]').forEach(initializePhilippineLocationPicker);

    let googleMapsPromise;
    const loadGoogleMaps = (key) => {
        if (window.google?.maps) {
            return Promise.resolve(window.google.maps);
        }
        if (googleMapsPromise) {
            return googleMapsPromise;
        }

        googleMapsPromise = new Promise((resolve, reject) => {
            const callbackName = '__jeapMapsReady';
            const script = document.createElement('script');
            let timeout;
            window[callbackName] = () => {
                window.clearTimeout(timeout);
                delete window[callbackName];
                resolve(window.google.maps);
            };
            script.async = true;
            script.defer = true;
            script.dataset.jeapMaps = 'true';
            script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(key)}&libraries=places&loading=async&callback=${callbackName}&language=en&region=PH`;
            script.onerror = () => {
                window.clearTimeout(timeout);
                delete window[callbackName];
                googleMapsPromise = null;
                reject(new Error('Google Maps could not be loaded.'));
            };
            timeout = window.setTimeout(() => {
                delete window[callbackName];
                googleMapsPromise = null;
                reject(new Error('Google Maps took too long to load.'));
            }, 15000);
            document.head.append(script);
        });

        return googleMapsPromise;
    };

    const initializeMapPicker = async (picker) => {
        if (picker.dataset.mapInitialized === 'true') {
            return;
        }
        picker.dataset.mapInitialized = 'true';

        const form = picker.closest('form');
        const status = picker.querySelector('[data-map-status]');
        const canvas = picker.querySelector('[data-map-canvas]');
        const search = picker.querySelector('[data-map-search]');
        const locateButton = picker.querySelector('[data-map-geolocate]');
        const coordinateText = picker.querySelector('[data-map-coordinates]');
        const latitude = form?.querySelector(`[name="${picker.dataset.latitudeField}"]`);
        const longitude = form?.querySelector(`[name="${picker.dataset.longitudeField}"]`);
        const addressSelector = picker.dataset.addressSelector
            ? form?.querySelector(`[name="${picker.dataset.addressSelector}"]`)
            : null;
        const entry = form?.querySelector('[data-address-entry]');
        const entryFields = [...(form?.querySelectorAll('[data-address-entry-field]') ?? [])];

        const setCoordinates = (position) => {
            const lat = Number(typeof position.lat === 'function' ? position.lat() : position.lat);
            const lng = Number(typeof position.lng === 'function' ? position.lng() : position.lng);
            if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
                return;
            }
            if (latitude) {
                latitude.value = lat.toFixed(7);
            }
            if (longitude) {
                longitude.value = lng.toFixed(7);
            }
            if (coordinateText) {
                coordinateText.textContent = `Selected coordinates: ${lat.toFixed(6)}, ${lng.toFixed(6)}`;
            }
        };

        const setField = (name, value) => {
            const field = form?.querySelector(`[name="${name}"]`);
            if (field && value !== undefined) {
                field.value = value ?? '';
            }
        };

        const addressValue = (place, type, short = false) => {
            const component = place.addressComponents?.find((item) => item.types.includes(type))
                ?? place.address_components?.find((item) => item.types.includes(type));
            return component ? (short
                ? (component.shortText ?? component.short_name ?? '')
                : (component.longText ?? component.long_name ?? '')) : '';
        };

        const fillAddressFromPlace = (place) => {
            const number = addressValue(place, 'street_number');
            const route = addressValue(place, 'route');
            const street = [number, route].filter(Boolean).join(' ') || place.formattedAddress || place.formatted_address || '';
            const city = addressValue(place, 'locality') || addressValue(place, 'postal_town') || addressValue(place, 'sublocality_level_1');
            const locationPicker = form?.querySelector('[data-philippine-location]');
            setField('street_line', street);
            setField('street', street);
            setField('country', addressValue(place, 'country') || 'Philippines');
            setField('postal_code', addressValue(place, 'postal_code'));
            setField('zip', addressValue(place, 'postal_code'));
            if (locationPicker) {
                locationPicker.dispatchEvent(new CustomEvent('jeap:manual-location', {
                    detail: {
                        region: addressValue(place, 'administrative_area_level_1'),
                        province: addressValue(place, 'administrative_area_level_2'),
                        city,
                        barangay: addressValue(place, 'sublocality_level_1'),
                        country: addressValue(place, 'country'),
                        country_code: addressValue(place, 'country', true).toUpperCase(),
                    },
                }));
            } else {
                setField('city_name', city);
                setField('city', city);
                setField('province_name', addressValue(place, 'administrative_area_level_1'));
                setField('province', addressValue(place, 'administrative_area_level_1'));
            }
        };

        const syncSelectedAddress = () => {
            if (!addressSelector) {
                return false;
            }
            const option = addressSelector.selectedOptions[0];
            const usingSavedAddress = Boolean(option?.value);
            if (entry) {
                entry.hidden = usingSavedAddress;
                entry.disabled = usingSavedAddress;
            }
            entryFields.forEach((field) => {
                field.disabled = usingSavedAddress;
            });
            if (latitude) {
                latitude.disabled = usingSavedAddress;
            }
            if (longitude) {
                longitude.disabled = usingSavedAddress;
            }

            if (usingSavedAddress && option) {
                const recipient = option.dataset.recipient?.trim().split(/\s+/) ?? [];
                setField('first_name', recipient.shift() ?? '');
                setField('last_name', recipient.join(' '));
                setField('phone', option.dataset.phone ?? '');
                setField('street', option.dataset.street ?? '');
                setField('street_line', option.dataset.street ?? '');
                setField('city', option.dataset.city ?? '');
                setField('city_name', option.dataset.city ?? '');
                setField('province', option.dataset.province ?? '');
                setField('province_name', option.dataset.province ?? '');
                setField('region_name', option.dataset.regionName ?? '');
                setField('barangay', option.dataset.barangay ?? '');
                setField('barangay_name', option.dataset.barangay ?? '');
                setField('region_code', option.dataset.regionCode ?? '');
                setField('province_code', option.dataset.provinceCode ?? '');
                setField('city_code', option.dataset.cityCode ?? '');
                setField('barangay_code', option.dataset.barangayCode ?? '');
                setField('country', 'Philippines');
                setField('country_name', option.dataset.countryName ?? 'Philippines');
                setField('country_code', option.dataset.countryCode ?? 'PH');
                setField('zip', option.dataset.zip ?? '');
                setField('postal_code', option.dataset.zip ?? '');
                if (latitude) {
                    latitude.value = option.dataset.latitude ?? '';
                }
                if (longitude) {
                    longitude.value = option.dataset.longitude ?? '';
                }
                form.querySelector('[data-philippine-location]')?.dispatchEvent(new CustomEvent('jeap:load-saved-address', {
                    detail: {
                        country_code: option.dataset.countryCode || 'PH',
                        country_name: option.dataset.countryName || 'Philippines',
                        region_code: option.dataset.regionCode,
                        region_name: option.dataset.regionName,
                        province_code: option.dataset.provinceCode,
                        province_name: option.dataset.province,
                        city_code: option.dataset.cityCode,
                        city_name: option.dataset.city,
                        barangay_code: option.dataset.barangayCode,
                        barangay_name: option.dataset.barangay,
                        postal_code: option.dataset.zip,
                    },
                }));
            }

            return usingSavedAddress;
        };

        const captureManualAddress = () => new Map(
            [...entryFields, latitude, longitude]
                .filter(Boolean)
                .map((field) => [field.name, field.value]),
        );
        let manualAddressValues = captureManualAddress();
        let savedAddressSelected = syncSelectedAddress();
        if (addressSelector) {
            addressSelector.addEventListener('change', () => {
                if (!savedAddressSelected && addressSelector.value) {
                    manualAddressValues = captureManualAddress();
                }
                const usingSavedAddress = syncSelectedAddress();
                if (savedAddressSelected && !usingSavedAddress) {
                    manualAddressValues.forEach((value, name) => {
                        const field = form?.querySelector(`[name="${name}"]`);
                        if (field) {
                            field.value = value;
                        }
                    });
                }
                savedAddressSelected = usingSavedAddress;
            picker.jeapMarker?.setDraggable(!usingSavedAddress);
            if (locateButton) {
                locateButton.disabled = usingSavedAddress;
            }
            if (picker.dataset.mapReady === 'true') {
                if (usingSavedAddress && latitude?.value && longitude?.value) {
                    const position = { lat: Number(latitude.value), lng: Number(longitude.value) };
                    picker.jeapMarker?.setPosition(position);
                    picker.jeapMap?.setCenter(position);
                    if (coordinateText) {
                        coordinateText.textContent = `Saved coordinates: ${latitude.value}, ${longitude.value}`;
                    }
                } else if (usingSavedAddress && coordinateText) {
                    coordinateText.textContent = 'This saved address has no pin coordinates yet.';
                }
            } else if (!usingSavedAddress && coordinateText) {
                coordinateText.textContent = 'Location coordinates not set.';
            }
        });
        }

        if (!picker.dataset.apiKey) {
            if (latitude?.value && longitude?.value && coordinateText) {
                coordinateText.textContent = `Saved coordinates: ${latitude.value}, ${longitude.value}`;
            }
            if (canvas) {
                canvas.hidden = true;
            }
            if (search) {
                search.closest('.delivery-map-search').hidden = true;
            }
            if (locateButton) {
                locateButton.hidden = true;
            }
            if (status) {
                status.textContent = 'Map is not configured yet. Enter the delivery address manually; map coordinates are optional.';
            }
            return;
        }

        if (savedAddressSelected) {
            if (status) {
                status.textContent = 'Using the selected saved address. Edit its pin on the Delivery addresses page.';
            }
        } else if (status) {
            status.textContent = 'Loading the map. You can still enter the delivery address manually.';
        }

        try {
            const maps = await loadGoogleMaps(picker.dataset.apiKey);
            const initialPosition = latitude?.value && longitude?.value
                ? { lat: Number(latitude.value), lng: Number(longitude.value) }
                : { lat: 14.5995, lng: 120.9842 };
            const map = new maps.Map(canvas, {
                center: initialPosition,
                zoom: latitude?.value && longitude?.value ? 16 : 12,
                mapTypeControl: false,
                streetViewControl: false,
                fullscreenControl: true,
                gestureHandling: 'cooperative',
            });
            const marker = new maps.Marker({
                position: initialPosition,
                map,
                draggable: !savedAddressSelected,
            });
            picker.jeapMap = map;
            picker.jeapMarker = marker;
            picker.dataset.mapReady = 'true';

            if (latitude?.value && longitude?.value) {
                setCoordinates(initialPosition);
            }

            map.addListener('click', (event) => {
                if (addressSelector?.value || !event.latLng) {
                    return;
                }
                marker.setPosition(event.latLng);
                setCoordinates(event.latLng);
                if (status) {
                    status.textContent = 'Pin selected. Fill in any missing address details.';
                }
            });
            marker.addListener('dragend', (event) => {
                if (addressSelector?.value || !event.latLng) {
                    return;
                }
                setCoordinates(event.latLng);
                if (status) {
                    status.textContent = 'Pin location updated.';
                }
            });

            if (search) {
                try {
                    const places = await maps.importLibrary('places');
                    const placeAutocomplete = new places.PlaceAutocompleteElement();
                    placeAutocomplete.includedRegionCodes = ['ph'];
                    placeAutocomplete.setAttribute('aria-label', 'Search for a delivery address');
                    search.replaceWith(placeAutocomplete);
                    placeAutocomplete.addEventListener('gmp-select', async ({ placePrediction }) => {
                        try {
                            const place = placePrediction.toPlace();
                            await place.fetchFields({
                                fields: ['addressComponents', 'formattedAddress', 'location'],
                            });
                            if (!place.location) {
                                if (status) {
                                    status.textContent = 'Choose an address from the search suggestions, or select a point on the map.';
                                }
                                return;
                            }
                            const position = place.location;
                            map.setCenter(position);
                            map.setZoom(17);
                            marker.setPosition(position);
                            setCoordinates(position);
                            fillAddressFromPlace(place);
                            if (status) {
                                status.textContent = place.formattedAddress
                                    ? `Selected: ${place.formattedAddress}`
                                    : 'Address selected. Check the delivery details before saving.';
                            }
                        } catch {
                            if (status) {
                                status.textContent = 'Address search failed. Select a point on the map or enter the address manually.';
                            }
                        }
                    });
                } catch {
                    if (search) {
                        search.disabled = true;
                        search.placeholder = 'Address search unavailable; select a point on the map';
                    }
                    if (status) {
                        status.textContent = 'Address search is unavailable. Select a point on the map or enter the address manually.';
                    }
                }
            }

            if (locateButton) {
                locateButton.disabled = savedAddressSelected;
                locateButton.addEventListener('click', () => {
                    if (!navigator.geolocation) {
                        if (status) {
                            status.textContent = 'Location services are unavailable in this browser. Select the pin manually.';
                        }
                        return;
                    }
                    locateButton.disabled = true;
                    navigator.geolocation.getCurrentPosition(
                        ({ coords }) => {
                            if (addressSelector?.value) {
                                return;
                            }
                            const position = { lat: coords.latitude, lng: coords.longitude };
                            map.setCenter(position);
                            map.setZoom(17);
                            marker.setPosition(position);
                            setCoordinates(position);
                            if (status) {
                                status.textContent = 'Current location selected. Check the pin and delivery address.';
                            }
                            locateButton.disabled = false;
                        },
                        (error) => {
                            if (status) {
                                status.textContent = error.code === error.PERMISSION_DENIED
                                    ? 'Location permission was denied. You can still select a pin manually.'
                                    : 'Could not get your location. You can still select a pin manually.';
                            }
                            locateButton.disabled = false;
                        },
                        { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 },
                    );
                });
            }

            if (status && !savedAddressSelected) {
                status.textContent = 'Tap the map or drag the pin to select the delivery point.';
            }
        } catch {
            picker.dataset.mapInitialized = 'false';
            if (canvas) {
                canvas.hidden = true;
            }
            if (search) {
                search.disabled = true;
                search.placeholder = 'Address search unavailable; enter the address manually';
            }
            if (status) {
                status.textContent = 'The map could not be loaded. Enter the address manually and try again later.';
            }
        }
    };

    document.querySelectorAll('[data-map-picker]').forEach((picker) => {
        const details = picker.closest('details');
        if (!details || details.open) {
            initializeMapPicker(picker);
        }
    });
    document.querySelectorAll('details').forEach((details) => {
        details.addEventListener('toggle', () => {
            if (details.open) {
                details.querySelectorAll('[data-map-picker]').forEach(initializeMapPicker);
            }
        });
    });

    document.querySelectorAll('[data-rider-action]').forEach((button) => button.addEventListener('click', async () => {
        button.disabled = true;
        await sendRiderAction(button.dataset.riderAction, button.dataset.action, new FormData());
    }));

    document.querySelectorAll('[data-rider-form]').forEach((form) => form.addEventListener('submit', async (event) => {
        event.preventDefault();
        const button = form.querySelector('button[type="submit"]');
        button.disabled = true;
        await sendRiderAction(form.dataset.assignment, form.dataset.action, new FormData(form));
    }));

    async function sendRiderAction(assignment, action, body) {
        const token = document.querySelector('meta[name="csrf-token"]')?.content;
        try {
            const response = await fetch(`/api/v1/rider/assignments/${assignment}/${action}`, {
                method: 'POST',
                credentials: 'same-origin',
                headers: { Accept: 'application/json', 'X-CSRF-TOKEN': token },
                body,
            });
            const data = await response.json();
            if (!response.ok) {
                throw new Error(data.message || 'This update could not be saved. Refresh and try again.');
            }
            window.location.reload();
        } catch (error) {
            window.alert(error.message);
            window.location.reload();
        }
    }

    const root = document.querySelector('[data-hero]');
    if (!root) {
        return;
    }

    const slides = [...root.querySelectorAll('.hero-slide')];
    if (slides.length < 2) {
        return;
    }

    let index = slides.findIndex((slide) => slide.classList.contains('is-active'));
    if (index < 0) {
        index = 0;
        slides[0].classList.add('is-active');
    }

    const show = (next) => {
        slides[index].classList.remove('is-active');
        index = (next + slides.length) % slides.length;
        slides[index].classList.add('is-active');
    };

    root.querySelector('[data-hero-prev]')?.addEventListener('click', () => show(index - 1));
    root.querySelector('[data-hero-next]')?.addEventListener('click', () => show(index + 1));
    setInterval(() => show(index + 1), 5000);
});
