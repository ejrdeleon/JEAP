<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class AnnouncementController extends Controller
{
    public function store(Request $request): RedirectResponse
    {
        $data = $this->validated($request);
        $data['is_published'] = $request->boolean('is_published');
        $data['published_at'] = $data['is_published'] ? now() : null;

        Announcement::query()->create($data);

        return back()->with('status', 'Announcement created.');
    }

    public function update(Request $request, Announcement $announcement): RedirectResponse
    {
        $data = $this->validated($request);
        $data['is_published'] = $request->boolean('is_published');
        $data['published_at'] = $data['is_published']
            ? ($announcement->published_at ?? now())
            : null;

        $announcement->update($data);

        return back()->with('status', 'Announcement updated.');
    }

    public function togglePublished(Announcement $announcement): RedirectResponse
    {
        $published = ! $announcement->is_published;
        $announcement->update([
            'is_published' => $published,
            'published_at' => $published ? now() : null,
        ]);

        return back()->with('status', $published ? 'Announcement published.' : 'Announcement unpublished.');
    }

    private function validated(Request $request): array
    {
        return $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'body' => ['required', 'string', 'max:10000'],
            'audience' => ['required', 'in:all,buyers,sellers'],
        ]);
    }
}
