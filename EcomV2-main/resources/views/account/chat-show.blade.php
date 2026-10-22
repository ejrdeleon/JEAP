@extends('layouts.storefront')

@section('title', ($conversation->subject ?: 'Chat').' | JEAP')
@section('crumb')
    <span>My account</span><span>/</span><span>Chat</span>
@endsection

@section('content')
<div class="account-page">
    <div class="chat-shell">
        <aside class="chat-list">
            @foreach($conversations as $item)
                <a class="chat-list-item {{ $item->id === $conversation->id ? 'is-current' : '' }} {{ $item->unread_count ? 'is-unread' : '' }}" href="{{ route('chat.show', $item) }}">
                    <strong>{{ $item->counterpart?->name ?? $item->subject ?? 'JEAP chat' }}</strong>
                    <p>{{ $item->latestMessage?->body ?? 'No messages yet' }}</p>
                </a>
            @endforeach
        </aside>
        <section class="chat-thread" data-chat-thread data-conversation="{{ $conversation->id }}" data-poll="{{ route('chat.messages', $conversation) }}">
            <header class="chat-thread-head">
                <div>
                    <strong>{{ $conversation->otherParticipant(auth()->user())?->name ?? 'JEAP chat' }}</strong>
                    @if($conversation->order)<p><a href="{{ route('buyer.orders.track', $conversation->order) }}">{{ $conversation->order->order_number }}</a></p>@endif
                </div>
            </header>
            <div class="chat-messages" data-chat-log>
                @foreach($conversation->messages as $message)
                    <div class="chat-bubble {{ $message->user_id === auth()->id() ? 'is-mine' : '' }}" data-message-id="{{ $message->id }}">
                        @unless($message->user_id === auth()->id())<small>{{ $message->sender?->name }}</small>@endunless
                        <p>{{ $message->body }}</p>
                        <time>{{ $message->created_at?->format('g:i A') }}</time>
                    </div>
                @endforeach
            </div>
            <form class="chat-compose" method="post" action="{{ route('chat.send', $conversation) }}" data-chat-form>
                @csrf
                <label class="sr-only" for="chat-message">Message</label>
                <textarea id="chat-message" name="message" maxlength="{{ config('jeap.chat_message_max') }}" required placeholder="Write a message"></textarea>
                <button class="s3-btn" type="submit">Send</button>
            </form>
        </section>
    </div>
</div>
<script>
    const thread = document.querySelector('[data-chat-thread]');
    const log = document.querySelector('[data-chat-log]');
    const form = document.querySelector('[data-chat-form]');
    const input = document.querySelector('#chat-message');
    const append = (message) => {
        if (log.querySelector(`[data-message-id="${message.id}"]`)) return;
        const bubble = document.createElement('div');
        bubble.className = `chat-bubble ${message.mine ? 'is-mine' : ''}`;
        bubble.dataset.messageId = message.id;
        bubble.innerHTML = `${message.mine ? '' : `<small>${message.sender ?? ''}</small>`}<p></p><time>${message.at ?? ''}</time>`;
        bubble.querySelector('p').textContent = message.body;
        log.appendChild(bubble);
        log.scrollTop = log.scrollHeight;
    };
    log.scrollTop = log.scrollHeight;
    form?.addEventListener('submit', async (event) => {
        event.preventDefault();
        const token = document.querySelector('meta[name="csrf-token"]')?.content;
        const body = new URLSearchParams({ message: input.value, _token: token });
        const response = await fetch(form.action, {
            method: 'POST',
            headers: { Accept: 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
            body,
        });
        const data = await response.json();
        if (response.ok) {
            append(data);
            input.value = '';
        }
    });
    const lastId = () => Number(log.querySelector('.chat-bubble:last-child')?.dataset.messageId || 0);
    setInterval(async () => {
        const response = await fetch(`${thread.dataset.poll}?after=${lastId()}`, { headers: { Accept: 'application/json' } });
        const data = await response.json();
        (data.messages || []).forEach(append);
    }, 4000);
</script>
@endsection
