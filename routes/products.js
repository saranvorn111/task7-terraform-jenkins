const express = require("express");
const router = express.Router();

const products = require("../data/products");

// Get all products
router.get("/", (req, res) => {
    res.json(products);
});

// Get product by ID
router.get("/:id", (req, res) => {

    const id = Number(req.params.id);

    const product = products.find(p => p.id === id);

    if (!product) {
        return res.status(404).json({
            message: "Product not found"
        });
    }

    res.json(product);
});

module.exports = router;