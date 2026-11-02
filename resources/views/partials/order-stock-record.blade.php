<div class="stock-record">
    <table>
        <thead>
            <tr>
                <th>Item</th>
                <th>Qty</th>
                <th>Stock before</th>
                <th>Stock after</th>
                <th>Line total</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($order->items as $item)
                <tr>
                    <td>
                        <strong>{{ $item->name }}</strong>
                        @if ($item->sku)<small>{{ $item->sku }}</small>@endif
                    </td>
                    <td>{{ $item->quantity }}</td>
                    <td>{{ $item->hasStockTrail() ? $item->stock_before : '—' }}</td>
                    <td>{{ $item->hasStockTrail() ? $item->stock_after : '—' }}</td>
                    <td>₱{{ number_format((float) $item->subtotal, 2) }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</div>
