# Rapid Iteration Plan - What We Have For Lunch

## 8-Week MVP Sprint

### Week 1-2: Core Foundation
**Goal**: Basic app with user preferences
- Flutter project setup + navigation
- Local database (Drift) with user preferences
- Simple onboarding flow
- **Deliverable**: Users can set diet preferences and see placeholder recommendations

### Week 3-4: Maps + Restaurant Data  
**Goal**: Real restaurant discovery
- Google Maps integration
- Restaurant search API
- Basic restaurant list/map view
- **Deliverable**: Users can see nearby restaurants on map

### Week 5-6: AI Recommendations
**Goal**: Working recommendation engine
- Gemini API integration
- Simple recommendation logic
- Top 3 restaurant cards with basic reasoning
- **Deliverable**: AI-powered restaurant suggestions

### Week 7-8: Polish + Launch
**Goal**: App store ready
- UI/UX refinements
- Performance optimization
- Beta testing with 20 users
- **Deliverable**: Published app in app stores

## Minimum Viable Features

### Must Have (Week 1-6)
- ✅ User preferences (diet, budget, location)
- ✅ Restaurant search via Google Maps
- ✅ AI recommendations (top 3 with reasoning)
- ✅ Basic directions to restaurant

### Nice to Have (Week 7-8)
- ⚡ Meal logging
- ⚡ Budget tracking
- ⚡ Favorites/history

### Later Phases
- 📱 Photo meal logging
- 🎯 Advanced budget analytics  
- 👥 Social features

## Success Metrics (8 weeks)

**Technical**:
- App launches in <3 seconds
- Recommendations load in <5 seconds
- <5% crash rate

**User**:
- 80% complete onboarding
- 50% accept at least one recommendation
- 100+ downloads in first week

## Risk Mitigation

**Week 1**: If Flutter setup delayed → Use template/boilerplate
**Week 3**: If Maps API costly → Implement aggressive caching immediately  
**Week 5**: If AI quality poor → Add manual rule-based fallback
**Week 7**: If performance issues → Remove non-critical features

## Resource Requirements

**Team**: 2 developers (1 senior Flutter + 1 backend)
**Budget**: $60K development + $5K APIs/tools
**APIs**: Google Maps ($200 credit), Gemini (free tier)

## Weekly Checkpoints

**Every Friday**: Demo working features to stakeholders
**Blockers**: Max 2 days to resolve or pivot
**Metrics**: Track daily active test users from Week 6

## Post-MVP (Week 9+)

**Month 2**: Diet tracking + budget features
**Month 3**: Advanced AI + social features  
**Month 4**: Revenue features + partnerships

**Target**: 1000 users by Month 3, $5K MRR by Month 6