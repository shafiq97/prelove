document.addEventListener("DOMContentLoaded", function() {
    const sellOption = document.getElementById("sell");
    const donateOption = document.getElementById("donate");
    const priceSection = document.getElementById("price-section");
    const donationSection = document.getElementById("donation-section");
    const itemName = document.getElementById("item-name");
    const itemCondition = document.getElementById("item-condition");
    const valuationDisplay = document.getElementById("item-valuation");

    const openCameraButton = document.getElementById("open-camera");
    const video = document.getElementById("camera-preview");
    const canvas = document.getElementById("captured-image");
    const cameraImageInput = document.getElementById("camera-image");

    let stream = null;

    // Toggle sell or donate options
    sellOption.addEventListener("change", function() {
        priceSection.style.display = "block";
        donationSection.style.display = "none";
    });

    donateOption.addEventListener("change", function() {
        priceSection.style.display = "none";
        donationSection.style.display = "block";
    });

    // Auto-generate item valuation based on name & condition
    itemName.addEventListener("input", generateValuation);
    itemCondition.addEventListener("change", generateValuation);

    function generateValuation() {
        let baseValue = 20; // Base price for used items
        if (itemCondition.value === "New") baseValue += 30;
        else if (itemCondition.value === "Like New") baseValue += 20;
        else if (itemCondition.value === "Good") baseValue += 10;
        valuationDisplay.textContent = `RM${baseValue.toFixed(2)}`;
    }
});

// Open camera for taking pictures
openCameraButton.addEventListener("click", async function() {
    if (!stream) {
        try {
            stream = await navigator.mediaDevices.getUserMedia({ video: true });
            video.srcObject = stream;
            video.style.display = "block";
            openCameraButton.textContent = "📸 Capture";
        } catch (error) {
            alert("Camera access denied.");
        }
    } else {
        // Capture image from video
        const context = canvas.getContext("2d");
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        context.drawImage(video, 0, 0, canvas.width, canvas.height);
        const imageDataURL = canvas.toDataURL("image/png");

        // Store image in hidden input
        cameraImageInput.value = imageDataURL;
        video.style.display = "none";
        stream.getTracks().forEach(track => track.stop());
        stream = null;
        openCameraButton.textContent = "📸 Take a Picture";
    }
});

