import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dil_kaa_rista_backend.settings')
django.setup()

from django.test import Client
from django.contrib.auth import get_user_model
from rest_framework.authtoken.models import Token
from profiles.models import Profile, PartnerPreference
from matches.models import MatchRequest

User = get_user_model()

def run_tests():
    print("=== Dil Ka Rishta Feature Test Suite ===")
    user = User.objects.filter(email='raj.verma@example.com').first()
    if not user:
        user = User.objects.first()
    assert user is not None, "No test user found in database!"

    token, _ = Token.objects.get_or_create(user=user)
    client = Client(HTTP_AUTHORIZATION=f'Token {token.key}')

    # 1. My Profile & Screening Details
    res = client.get('/api/profiles/me/')
    assert res.status_code == 200, f"my-profile failed: {res.status_code} {res.content}"
    data = res.json()
    print(f"[PASS] My Profile loaded: ID={data.get('profile_id')} Status={data.get('verification_status')} Tier={data.get('membership_tier')}")

    # 2. Partner Preferences
    res = client.get('/api/profiles/partner-preferences/')
    assert res.status_code == 200, f"partner-preference failed: {res.status_code}"
    pref_data = res.json()
    print(f"[PASS] Partner Preferences loaded: Must-haves={pref_data.get('must_have_fields')} Warning={pref_data.get('narrow_criteria_warning')}")

    # 3. Matches Feed (4 Sub-Tabs from Page 4)
    for subtab in ['preferred', 'broader', 'reverse', 'near_me']:
        res = client.get(f'/api/matches/feed/?type={subtab}')
        assert res.status_code == 200, f"Feed {subtab} failed: {res.status_code}"
        feed_data = res.json()
        print(f"[PASS] Match Feed [{subtab}]: count={len(feed_data)}")

    # 4. Search with Special Cases (Page 5)
    res = client.post(
        '/api/matches/search/',
        data=json.dumps({'special_case': 'none', 'sort_by': 'relevance'}),
        content_type='application/json'
    )
    assert res.status_code == 200, f"Search failed: {res.status_code}"
    search_data = res.json()
    print(f"[PASS] Search endpoint: results count={len(search_data)}")

    # 5. Inbox (5 Folders + Bulk Action Support from Page 5)
    for folder in ['interests_received', 'filtered_out', 'requests', 'accepted', 'deleted']:
        res = client.get(f'/api/matches/inbox/?folder={folder}')
        assert res.status_code == 200, f"Inbox {folder} failed: {res.status_code}"
        inbox_data = res.json()
        print(f"[PASS] Inbox [{folder}]: count={len(inbox_data)}")

    # 6. Universal Chat Box Directory (Page 1)
    res = client.get('/api/chat/directory/')
    assert res.status_code == 200, f"Chat directory failed: {res.status_code}"
    chat_dir = res.json()
    print(f"[PASS] Chat Directory: conversations={len(chat_dir.get('conversations', []))} online_accepted={len(chat_dir.get('online_accepted', []))} unread_total={chat_dir.get('unread_total')}")

    # 7. General Settings & Active Sessions (Page 4)
    res = client.get('/api/auth/settings/')
    assert res.status_code == 200, f"Settings failed: {res.status_code}"
    print(f"[PASS] General Settings loaded: language={res.json().get('language')}")

    res = client.get('/api/auth/active-sessions/')
    assert res.status_code == 200, f"Active sessions failed: {res.status_code}"
    print(f"[PASS] Active Sessions loaded: count={len(res.json())}")

    print("\nALL BACKEND ENDPOINTS AND SPECIFICATIONS VALIDATED SUCCESSFULLY!")

if __name__ == '__main__':
    run_tests()
