<?php

namespace Database\Seeders;

use App\Enums\UserStatus;
use App\Models\Category;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class CatalogSeeder extends Seeder
{
    public function run(): void
    {
        User::query()->where('email', 'seller@jmart.test')->update(['email' => 'seller@jeap.test']);

        $seller = User::query()->updateOrCreate(
            ['email' => 'seller@jeap.test'],
            [
                'first_name' => 'Demo',
                'last_name' => 'Seller',
                'phone' => '09171234567',
                'password' => env('SEED_USER_PASSWORD', 'password'),
                'email_verified_at' => now(),
            ]
        );
        $seller->forceFill(['status' => UserStatus::Active])->save();
        $seller->syncRoles(['seller']);
        $seller->sellerProfile()->updateOrCreate(
            ['user_id' => $seller->id],
            ['business_name' => 'JEAP Demo Electronics']
        );

        $categories = [
            ['name' => 'Gaming', 'file' => 'cat-gaming.png'],
            ['name' => 'Sport Equip', 'file' => 'cat-sport.png'],
            ['name' => 'Kitchen', 'file' => 'cat-kitchen.png'],
            ['name' => 'Robot Cleaner', 'file' => 'cat-robot.png'],
            ['name' => 'Mobiles', 'file' => 'cat-mobiles.png'],
            ['name' => 'Office', 'file' => 'cat-office.png'],
            ['name' => 'Cameras', 'file' => 'cat-cameras.png'],
            ['name' => 'Computers', 'file' => 'cat-computers.png'],
            ['name' => 'Televisions', 'file' => 'cat-televisions.png'],
            ['name' => 'Audios', 'file' => 'cat-audios.png'],
        ];

        $models = [];
        foreach ($categories as $i => $row) {
            $models[$row['name']] = Category::query()->updateOrCreate(
                ['slug' => Str::slug($row['name'])],
                [
                    'name' => $row['name'],
                    'image_path' => 'images/categories/'.$row['file'],
                    'is_line_of_business' => true,
                    'is_active' => true,
                    'sort_order' => $i + 1,
                ]
            );
        }

        $catalog = [
            ['Air Purifier with HEPA Filter', 'Kitchen', 489, 619, 24, 80, '15% OFF'],
            ['Shaork Robot Vacuum', 'Robot Cleaner', 325, 428, 1, 19, '5% OFF'],
            ['Durotan Manual Espresso Machine', 'Kitchen', 489, 619, 82, 100, '15% OFF'],
            ['Sona QLED Ultra HD 4K Smart TV', 'Televisions', 1759, 2069, 7, 85, '15% OFF'],
            ['iPad mini 2023 Wi-Fi 256GB', 'Computers', 699, 799, 12, 40, null],
            ['Marshall Standmore Speaker Black', 'Audios', 289, 349, 18, 50, 'top rated'],
            ['Gaming Console Bundle', 'Gaming', 559, 629, 9, 30, 'best seller'],
            ['Pro Mirrorless Camera Kit', 'Cameras', 1299, 1499, 4, 20, null],
            ['Ultrabook 14-inch Office Laptop', 'Office', 899, 999, 11, 25, null],
            ['Flagship 5G Smartphone', 'Mobiles', 799, 899, 22, 60, '15% OFF'],
        ];

        foreach ($catalog as $i => $row) {
            [$name, $cat, $price, $compare, $sold, $stock, $badge] = $row;
            $category = $models[$cat];
            $image = $category->image_path;

            $product = Product::query()->updateOrCreate(
                ['slug' => Str::slug($name)],
                [
                    'seller_id' => $seller->id,
                    'category_id' => $category->id,
                    'name' => $name,
                    'description' => $name.' available on JEAP with in-house delivery.',
                    'status' => 'active',
                    'is_featured' => $i < 4,
                ]
            );

            $variant = $product->variants()->updateOrCreate(
                ['sku' => 'JM-'.str_pad((string) ($i + 1), 4, '0', STR_PAD_LEFT)],
                [
                    'price' => $price,
                    'compare_at_price' => $compare,
                    'stock' => $stock,
                    'is_active' => true,
                    'attributes' => ['sold' => $sold, 'badge' => $badge],
                ]
            );

            $product->images()->updateOrCreate(
                ['path' => $image],
                ['alt' => $name, 'sort_order' => 0, 'variant_id' => $variant->id]
            );
        }
    }
}
