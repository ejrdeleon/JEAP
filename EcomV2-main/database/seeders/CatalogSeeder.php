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
            ['business_name' => 'JEAP Demo Shop']
        );

        $tree = [
            ['Women\'s Apparel', null],
            ['Men\'s Apparel', null],
            ['Mobile & Gadgets', ['Mobiles' => 'cat-mobiles.png']],
            ['Computers & Office', ['Computers' => 'cat-computers.png', 'Office' => 'cat-office.png']],
            ['Consumer Electronics', ['Televisions' => 'cat-televisions.png', 'Audios' => 'cat-audios.png', 'Cameras' => 'cat-cameras.png', 'Gaming' => 'cat-gaming.png']],
            ['Home Appliances', ['Kitchen' => 'cat-kitchen.png', 'Robot Cleaner' => 'cat-robot.png']],
            ['Home & Living', null],
            ['Beauty & Personal Care', null],
            ['Groceries', null],
            ['Sports & Outdoor', ['Sport Equip' => 'cat-sport.png']],
            ['Toys, Kids & Babies', null],
            ['Automotive', null],
            ['Pet Care', null],
            ['Fashion Accessories', null],
            ['Bags', null],
            ['Watches', null],
        ];

        $models = [];
        foreach ($tree as $index => [$parentName, $children]) {
            $parent = Category::query()->updateOrCreate(
                ['slug' => Str::slug($parentName)],
                [
                    'name' => $parentName,
                    'parent_id' => null,
                    'is_line_of_business' => true,
                    'is_active' => true,
                    'sort_order' => ($index + 1) * 10,
                ]
            );
            $models[$parentName] = $parent;

            foreach ($children ?? [] as $childName => $file) {
                $models[$childName] = Category::query()->updateOrCreate(
                    ['slug' => Str::slug($childName)],
                    [
                        'name' => $childName,
                        'parent_id' => $parent->id,
                        'image_path' => 'images/categories/'.$file,
                        'is_line_of_business' => false,
                        'is_active' => true,
                        'sort_order' => $parent->sort_order + array_search($childName, array_keys($children), true) + 1,
                    ]
                );
            }
        }

        $catalog = [
            ['Air Purifier with HEPA Filter', 'Kitchen', 489, 619, 24, 80, null],
            ['Shaork Robot Vacuum', 'Robot Cleaner', 325, 428, 12, 19, null],
            ['Durotan Manual Espresso Machine', 'Kitchen', 489, 619, 82, 100, null],
            ['Sona QLED Ultra HD 4K Smart TV', 'Televisions', 1759, 2069, 7, 85, null],
            ['iPad mini 2023 Wi-Fi 256GB', 'Computers', 699, 799, 12, 40, null],
            ['Marshall Standmore Speaker Black', 'Audios', 289, 349, 18, 50, null],
            ['Gaming Console Bundle', 'Gaming', 559, 629, 9, 30, null],
            ['Pro Mirrorless Camera Kit', 'Cameras', 1299, 1499, 14, 20, null],
            ['Ultrabook 14-inch Office Laptop', 'Office', 899, 999, 11, 25, null],
            ['Flagship 5G Smartphone', 'Mobiles', 799, 899, 22, 60, null],
        ];

        foreach ($catalog as $i => $row) {
            [$name, $cat, $price, $compare, $sold, $stock] = $row;
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
                    'attributes' => ['sold' => $sold],
                ]
            );

            if ($image) {
                $product->images()->updateOrCreate(
                    ['path' => $image],
                    ['alt' => $name, 'sort_order' => 0, 'variant_id' => $variant->id]
                );
            }
        }
    }
}
