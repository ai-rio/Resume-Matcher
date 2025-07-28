# Data Protection & Privacy

## Overview

This document outlines comprehensive data protection and privacy measures for the Resume-Matcher SaaS platform, ensuring compliance with GDPR, CCPA, and other privacy regulations while maintaining the highest security standards.

## Data Classification

### Personal Data Categories

#### Tier 1: Highly Sensitive Data
- **Resume Content**: Full text, parsed data, skills, experience
- **Job Search History**: Companies applied to, positions sought
- **Authentication Credentials**: Passwords, MFA secrets
- **Payment Information**: Credit card details (tokenized), billing addresses

**Protection Level**: Encrypted at rest and in transit, restricted access, audit logging

#### Tier 2: Sensitive Personal Data
- **Profile Information**: Name, email, phone, company, job title
- **Usage Analytics**: Feature usage, session data, performance metrics
- **Support Communications**: Tickets, chat logs, feedback

**Protection Level**: Encrypted at rest, controlled access, privacy controls

#### Tier 3: General Business Data
- **Account Metadata**: Subscription status, plan details, preferences
- **System Logs**: Application logs, error logs (anonymized)
- **Aggregated Analytics**: Platform usage statistics (anonymized)

**Protection Level**: Standard encryption, role-based access

## Data Collection Principles

### Lawful Basis for Processing

#### Legitimate Interests
- **Service Improvement**: Analyzing usage patterns to enhance features
- **Security**: Monitoring for fraud and security threats
- **Business Operations**: Customer support, billing, account management

#### Contractual Necessity
- **Service Delivery**: Processing resumes, providing analysis results
- **Account Management**: User authentication, subscription management
- **Payment Processing**: Billing and transaction processing

#### Consent
- **Marketing Communications**: Email newsletters, product updates
- **Cookies**: Non-essential cookies, analytics tracking
- **Third-party Integrations**: LinkedIn profile import, Google Drive sync

### Data Minimization Strategy

```typescript
// Example: Data collection validation
interface DataCollectionConfig {
  purpose: string
  lawfulBasis: 'consent' | 'contract' | 'legitimate_interest' | 'legal_obligation'
  dataTypes: string[]
  retentionPeriod: number // days
  accessControl: 'public' | 'internal' | 'restricted'
}

const resumeAnalysisCollection: DataCollectionConfig = {
  purpose: 'Resume analysis and job matching',
  lawfulBasis: 'contract',
  dataTypes: ['resume_text', 'job_preferences', 'analysis_results'],
  retentionPeriod: 2555, // 7 years
  accessControl: 'restricted'
}

const marketingCollection: DataCollectionConfig = {
  purpose: 'Product updates and marketing',
  lawfulBasis: 'consent',
  dataTypes: ['email', 'usage_patterns'],
  retentionPeriod: 1095, // 3 years or until consent withdrawn
  accessControl: 'internal'
}
```

## Privacy by Design Implementation

### Technical Measures

#### Data Encryption

```typescript
// End-to-end encryption for sensitive data
export class DataEncryption {
  private static readonly ALGORITHM = 'aes-256-gcm'
  private static readonly KEY_LENGTH = 32
  private static readonly IV_LENGTH = 16

  static async encryptSensitiveData(
    data: string,
    userKey: string
  ): Promise<EncryptedData> {
    const key = crypto.scryptSync(userKey, 'salt', this.KEY_LENGTH)
    const iv = crypto.randomBytes(this.IV_LENGTH)
    const cipher = crypto.createCipher(this.ALGORITHM, key, iv)
    
    let encrypted = cipher.update(data, 'utf8', 'hex')
    encrypted += cipher.final('hex')
    
    return {
      data: encrypted,
      iv: iv.toString('hex'),
      authTag: cipher.getAuthTag().toString('hex')
    }
  }

  static async decryptSensitiveData(
    encryptedData: EncryptedData,
    userKey: string
  ): Promise<string> {
    const key = crypto.scryptSync(userKey, 'salt', this.KEY_LENGTH)
    const decipher = crypto.createDecipher(
      this.ALGORITHM,
      key,
      Buffer.from(encryptedData.iv, 'hex')
    )
    
    decipher.setAuthTag(Buffer.from(encryptedData.authTag, 'hex'))
    
    let decrypted = decipher.update(encryptedData.data, 'hex', 'utf8')
    decrypted += decipher.final('utf8')
    
    return decrypted
  }
}
```

#### Data Anonymization

```sql
-- Database function for data anonymization
CREATE OR REPLACE FUNCTION anonymize_user_data(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Anonymize personal information
    UPDATE profiles SET
        email = 'deleted_' || p_user_id || '@example.com',
        full_name = 'Deleted User',
        company = NULL,
        job_title = NULL,
        avatar_url = NULL,
        preferences = '{}'::jsonb
    WHERE id = p_user_id;
    
    -- Anonymize resume content while preserving analytics
    UPDATE resumes SET
        title = 'Anonymized Resume',
        filename = 'anonymized.pdf',
        content_text = '[Content removed for privacy]',
        parsed_data = jsonb_build_object(
            'anonymized', true,
            'original_skills_count', jsonb_array_length(parsed_data->'skills'->0),
            'original_experience_years', parsed_data->'experience'->0->'duration'
        )
    WHERE user_id = p_user_id;
    
    -- Keep aggregated analytics data
    INSERT INTO anonymized_analytics (
        original_user_id,
        user_type,
        total_analyses,
        avg_session_duration,
        feature_usage,
        anonymized_at
    )
    SELECT 
        p_user_id,
        'deleted_user',
        COUNT(ma.id),
        AVG(EXTRACT(EPOCH FROM (ma.created_at - us.created_at))),
        jsonb_agg(DISTINCT ma.metadata->>'analysis_type'),
        NOW()
    FROM matching_analyses ma
    JOIN usage_summaries us ON ma.user_id = us.user_id
    WHERE ma.user_id = p_user_id;
    
    RETURN TRUE;
END;
$$;
```

### Organizational Measures

#### Privacy Impact Assessment (PIA)

```typescript
interface PrivacyImpactAssessment {
  feature: string
  dataTypes: string[]
  purposes: string[]
  lawfulBasis: string
  risks: PrivacyRisk[]
  mitigations: string[]
  approvedBy: string
  reviewDate: Date
}

const resumeAnalysisPIA: PrivacyImpactAssessment = {
  feature: 'AI Resume Analysis',
  dataTypes: [
    'resume_content',
    'personal_information', 
    'employment_history',
    'skills_data'
  ],
  purposes: [
    'Provide resume optimization suggestions',
    'Match candidates with job requirements',
    'Generate analytics and insights'
  ],
  lawfulBasis: 'contractual_necessity',
  risks: [
    {
      risk: 'Unauthorized access to sensitive career information',
      likelihood: 'low',
      impact: 'high',
      riskLevel: 'medium'
    },
    {
      risk: 'Inference of protected characteristics from resume data',
      likelihood: 'medium',
      impact: 'high',
      riskLevel: 'high'
    }
  ],
  mitigations: [
    'End-to-end encryption of resume content',
    'Role-based access controls',
    'Regular security audits',
    'AI bias testing and monitoring',
    'Data retention limits'
  ],
  approvedBy: 'privacy_officer',
  reviewDate: new Date('2024-07-01')
}
```

## Data Subject Rights Implementation

### Right to Access (Article 15 GDPR)

```typescript
// Service for handling data access requests
export class DataAccessService {
  async generateUserDataExport(userId: string): Promise<UserDataExport> {
    const userProfile = await this.getUserProfile(userId)
    const resumes = await this.getUserResumes(userId)
    const analyses = await this.getUserAnalyses(userId)
    const usage = await this.getUserUsage(userId)
    const subscriptions = await this.getUserSubscriptions(userId)
    
    return {
      exportDate: new Date(),
      userProfile: {
        ...userProfile,
        // Remove internal system fields
        created_at: userProfile.created_at,
        updated_at: userProfile.updated_at
      },
      resumes: resumes.map(resume => ({
        id: resume.id,
        title: resume.title,
        uploadDate: resume.created_at,
        fileSize: resume.file_size,
        analysisCount: resume.analysis_count
        // Note: Actual file content available through separate endpoint
      })),
      analyses: analyses.map(analysis => ({
        id: analysis.id,
        resumeId: analysis.resume_id,
        jobTitle: analysis.job_title,
        overallScore: analysis.overall_score,
        date: analysis.created_at,
        recommendations: analysis.recommendations
      })),
      usage: {
        totalAnalyses: usage.total_analyses,
        totalUploads: usage.total_uploads,
        storageUsed: usage.storage_used,
        accountAge: usage.account_age_days
      },
      subscriptions: subscriptions.map(sub => ({
        planName: sub.plan_name,
        status: sub.status,
        startDate: sub.created_at,
        endDate: sub.current_period_end
      }))
    }
  }

  async downloadUserFiles(userId: string): Promise<FileDownloadUrls> {
    const resumes = await this.getUserResumes(userId)
    const signedUrls = await Promise.all(
      resumes.map(async resume => {
        const url = await this.storageService.createSignedUrl(
          resume.file_path,
          3600 // 1 hour expiry
        )
        return {
          resumeId: resume.id,
          fileName: resume.filename,
          downloadUrl: url
        }
      })
    )
    
    return { files: signedUrls, expiresAt: new Date(Date.now() + 3600000) }
  }
}
```

### Right to Rectification (Article 16 GDPR)

```typescript
// Profile update with validation and audit
export class ProfileUpdateService {
  async updateProfile(
    userId: string,
    updates: Partial<UserProfile>,
    requestedBy: string
  ): Promise<UserProfile> {
    // Validate update permissions
    if (requestedBy !== userId && !this.isAuthorizedAdmin(requestedBy)) {
      throw new Error('Unauthorized profile update')
    }
    
    // Audit log before update
    const currentProfile = await this.getUserProfile(userId)
    await this.auditService.logDataChange({
      userId,
      action: 'profile_update',
      oldValues: currentProfile,
      newValues: updates,
      requestedBy,
      timestamp: new Date()
    })
    
    // Update profile with validation
    const updatedProfile = await this.profileRepository.update(userId, {
      ...updates,
      updated_at: new Date()
    })
    
    // Notify user of changes
    await this.notificationService.sendProfileUpdateConfirmation(
      userId,
      Object.keys(updates)
    )
    
    return updatedProfile
  }
}
```

### Right to Erasure (Article 17 GDPR)

```typescript
// Complete data deletion service
export class DataDeletionService {
  async deleteUserAccount(
    userId: string,
    reason: DeletionReason,
    retainAnalytics: boolean = false
  ): Promise<DeletionReport> {
    const deletionId = uuidv4()
    
    try {
      // Start deletion transaction
      await this.db.transaction(async (trx) => {
        // Delete user files from storage
        const files = await this.getStorageFiles(userId)
        await this.storageService.deleteFiles(files.map(f => f.path))
        
        if (retainAnalytics) {
          // Anonymize data while preserving analytics
          await this.anonymizeUserData(userId, trx)
        } else {
          // Complete deletion
          await this.deleteUserData(userId, trx)
        }
        
        // Log deletion
        await this.auditService.logDataDeletion({
          deletionId,
          userId,
          reason,
          method: retainAnalytics ? 'anonymization' : 'complete_deletion',
          timestamp: new Date()
        }, trx)
      })
      
      // Send deletion confirmation
      await this.notificationService.sendDeletionConfirmation(
        userId,
        deletionId
      )
      
      return {
        deletionId,
        status: 'completed',
        deletedData: {
          profile: true,
          resumes: files.length,
          analyses: await this.getAnalysisCount(userId),
          subscriptions: true
        },
        retainedData: retainAnalytics ? ['anonymized_analytics'] : []
      }
      
    } catch (error) {
      await this.auditService.logDeletionFailure(deletionId, error)
      throw error
    }
  }
}
```

### Right to Data Portability (Article 20 GDPR)

```typescript
// Data export in machine-readable format
export class DataPortabilityService {
  async exportUserData(
    userId: string,
    format: 'json' | 'csv' | 'xml' = 'json'
  ): Promise<PortableDataExport> {
    const userData = await this.dataAccessService.generateUserDataExport(userId)
    
    switch (format) {
      case 'json':
        return {
          format: 'application/json',
          data: JSON.stringify(userData, null, 2),
          filename: `resume-matcher-data-${userId}.json`
        }
        
      case 'csv':
        const csvData = await this.convertToCSV(userData)
        return {
          format: 'text/csv',
          data: csvData,
          filename: `resume-matcher-data-${userId}.csv`
        }
        
      case 'xml':
        const xmlData = await this.convertToXML(userData)
        return {
          format: 'application/xml',
          data: xmlData,
          filename: `resume-matcher-data-${userId}.xml`
        }
    }
  }
  
  private async convertToCSV(userData: UserDataExport): Promise<string> {
    // Convert nested JSON to flat CSV structure
    const csvRows = []
    
    // Profile data
    csvRows.push(['Data Type', 'Field', 'Value'])
    Object.entries(userData.userProfile).forEach(([key, value]) => {
      csvRows.push(['Profile', key, String(value)])
    })
    
    // Resume data
    userData.resumes.forEach((resume, index) => {
      Object.entries(resume).forEach(([key, value]) => {
        csvRows.push([`Resume ${index + 1}`, key, String(value)])
      })
    })
    
    return csvRows.map(row => row.join(',')).join('\n')
  }
}
```

## Consent Management

### Consent Collection and Storage

```typescript
interface ConsentRecord {
  userId: string
  consentId: string
  purpose: string
  lawfulBasis: string
  consentGiven: boolean
  consentDate: Date
  consentMethod: 'explicit' | 'opt_in' | 'pre_checked' | 'inferred'
  consentText: string
  ipAddress: string
  userAgent: string
  withdrawalDate?: Date
  withdrawalMethod?: string
}

export class ConsentManager {
  async recordConsent(
    userId: string,
    consentData: Omit<ConsentRecord, 'consentId' | 'userId'>
  ): Promise<string> {
    const consentId = uuidv4()
    
    await this.consentRepository.create({
      ...consentData,
      userId,
      consentId
    })
    
    // Update user preferences
    await this.updateUserConsentPreferences(userId, consentData.purpose, true)
    
    return consentId
  }
  
  async withdrawConsent(
    userId: string,
    purpose: string,
    withdrawalMethod: string
  ): Promise<void> {
    await this.consentRepository.update(
      { userId, purpose },
      {
        consentGiven: false,
        withdrawalDate: new Date(),
        withdrawalMethod
      }
    )
    
    // Update user preferences
    await this.updateUserConsentPreferences(userId, purpose, false)
    
    // Stop related processing
    await this.stopProcessingForPurpose(userId, purpose)
  }
  
  async getConsentStatus(userId: string): Promise<ConsentStatus> {
    const consents = await this.consentRepository.findByUser(userId)
    
    return {
      marketing: this.getConsentForPurpose(consents, 'marketing'),
      analytics: this.getConsentForPurpose(consents, 'analytics'),
      thirdPartySharing: this.getConsentForPurpose(consents, 'third_party_sharing'),
      lastUpdated: Math.max(...consents.map(c => c.consentDate.getTime()))
    }
  }
}
```

### Cookie Consent Implementation

```typescript
// Frontend cookie consent component
export const CookieConsent: React.FC = () => {
  const [showBanner, setShowBanner] = useState(false)
  const [preferences, setPreferences] = useState({
    necessary: true, // Always true, cannot be disabled
    analytics: false,
    marketing: false,
    functional: false
  })

  useEffect(() => {
    const consent = localStorage.getItem('cookie-consent')
    if (!consent) {
      setShowBanner(true)
    } else {
      const parsedConsent = JSON.parse(consent)
      setPreferences(parsedConsent)
      initializeCookies(parsedConsent)
    }
  }, [])

  const acceptAll = async () => {
    const newPreferences = {
      necessary: true,
      analytics: true,
      marketing: true,
      functional: true
    }
    
    await saveConsentPreferences(newPreferences)
    setPreferences(newPreferences)
    setShowBanner(false)
    initializeCookies(newPreferences)
  }

  const acceptSelected = async () => {
    await saveConsentPreferences(preferences)
    setShowBanner(false)
    initializeCookies(preferences)
  }

  const saveConsentPreferences = async (prefs: CookiePreferences) => {
    localStorage.setItem('cookie-consent', JSON.stringify(prefs))
    localStorage.setItem('cookie-consent-date', new Date().toISOString())
    
    // Send to backend
    try {
      await api.post('/privacy/cookie-consent', {
        preferences: prefs,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent
      })
    } catch (error) {
      console.error('Failed to save cookie consent:', error)
    }
  }

  if (!showBanner) return null

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-gray-900 text-white p-4 z-50">
      <div className="max-w-6xl mx-auto">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
          <div className="flex-1">
            <h3 className="text-lg font-semibold mb-2">Cookie Preferences</h3>
            <p className="text-sm text-gray-300">
              We use cookies to enhance your experience, analyze site usage, and assist with marketing efforts.
            </p>
          </div>
          
          <div className="flex flex-col sm:flex-row gap-2">
            <Button variant="outline" onClick={() => setShowBanner(false)}>
              Customize
            </Button>
            <Button onClick={acceptAll}>
              Accept All
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}
```

## Data Breach Response

### Incident Response Plan

```typescript
interface DataBreachIncident {
  incidentId: string
  discoveredAt: Date
  reportedBy: string
  severity: 'low' | 'medium' | 'high' | 'critical'
  affectedUsers: number
  dataTypes: string[]
  breachVector: string
  containmentActions: string[]
  notificationRequired: boolean
  regulatoryReporting: boolean
  status: 'investigating' | 'contained' | 'resolved' | 'monitoring'
}

export class BreachResponseService {
  async reportDataBreach(
    incident: Omit<DataBreachIncident, 'incidentId'>
  ): Promise<string> {
    const incidentId = `BREACH-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
    
    // Immediate containment
    if (incident.severity === 'critical' || incident.severity === 'high') {
      await this.initiateEmergencyContainment(incident)
    }
    
    // Store incident record
    await this.incidentRepository.create({
      ...incident,
      incidentId
    })
    
    // Notify incident response team
    await this.notifyIncidentTeam(incidentId, incident)
    
    // Start investigation
    await this.startInvestigation(incidentId)
    
    return incidentId
  }
  
  async assessNotificationRequirements(
    incidentId: string
  ): Promise<NotificationAssessment> {
    const incident = await this.incidentRepository.findById(incidentId)
    
    // GDPR Article 33 - Notification to supervisory authority
    const supervisoryNotificationRequired = (
      incident.severity === 'high' || 
      incident.severity === 'critical' ||
      incident.affectedUsers > 100
    )
    
    // GDPR Article 34 - Notification to data subjects
    const dataSubjectNotificationRequired = (
      incident.severity === 'critical' ||
      (incident.severity === 'high' && incident.dataTypes.includes('sensitive_personal_data'))
    )
    
    return {
      supervisoryAuthority: {
        required: supervisoryNotificationRequired,
        deadline: supervisoryNotificationRequired ? 
          new Date(incident.discoveredAt.getTime() + 72 * 60 * 60 * 1000) : // 72 hours
          null
      },
      dataSubjects: {
        required: dataSubjectNotificationRequired,
        method: 'email_and_dashboard',
        timeline: 'without_undue_delay'
      },
      publicDisclosure: {
        required: incident.affectedUsers > 10000,
        channels: ['website', 'press_release', 'social_media']
      }
    }
  }
}
```

## Privacy Controls Dashboard

```typescript
// User privacy dashboard component
export const PrivacyDashboard: React.FC = () => {
  const [consentStatus, setConsentStatus] = useState<ConsentStatus | null>(null)
  const [dataUsage, setDataUsage] = useState<DataUsageSummary | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadPrivacyData()
  }, [])

  const loadPrivacyData = async () => {
    try {
      const [consent, usage] = await Promise.all([
        api.get('/privacy/consent-status'),
        api.get('/privacy/data-usage')
      ])
      setConsentStatus(consent.data)
      setDataUsage(usage.data)
    } catch (error) {
      console.error('Failed to load privacy data:', error)
    } finally {
      setLoading(false)
    }
  }

  const updateConsent = async (purpose: string, granted: boolean) => {
    try {
      await api.post('/privacy/update-consent', { purpose, granted })
      await loadPrivacyData()
    } catch (error) {
      console.error('Failed to update consent:', error)
    }
  }

  const requestDataExport = async () => {
    try {
      const response = await api.post('/privacy/export-data')
      // Handle download or show confirmation
    } catch (error) {
      console.error('Failed to request data export:', error)
    }
  }

  const deleteAccount = async () => {
    if (confirm('Are you sure? This action cannot be undone.')) {
      try {
        await api.delete('/privacy/delete-account')
        // Redirect to goodbye page
      } catch (error) {
        console.error('Failed to delete account:', error)
      }
    }
  }

  return (
    <div className="max-w-4xl mx-auto p-6">
      <h1 className="text-2xl font-bold mb-6">Privacy & Data Controls</h1>
      
      {/* Consent Management */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <h2 className="text-xl font-semibold mb-4">Consent Preferences</h2>
        <div className="space-y-4">
          <ConsentToggle
            title="Marketing Communications"
            description="Receive product updates and marketing emails"
            enabled={consentStatus?.marketing || false}
            onChange={(enabled) => updateConsent('marketing', enabled)}
          />
          <ConsentToggle
            title="Analytics & Performance"
            description="Help us improve our service with usage analytics"
            enabled={consentStatus?.analytics || false}
            onChange={(enabled) => updateConsent('analytics', enabled)}
          />
        </div>
      </div>
      
      {/* Data Usage Summary */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <h2 className="text-xl font-semibold mb-4">Your Data Usage</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <DataUsageCard
            title="Resumes Stored"
            value={dataUsage?.resumesCount || 0}
            description="Resume files in your account"
          />
          <DataUsageCard
            title="Analyses Performed"
            value={dataUsage?.analysesCount || 0}
            description="Total resume analyses"
          />
          <DataUsageCard
            title="Storage Used"
            value={formatBytes(dataUsage?.storageUsed || 0)}
            description="File storage consumption"
          />
        </div>
      </div>
      
      {/* Data Rights */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold mb-4">Your Data Rights</h2>
        <div className="space-y-4">
          <Button onClick={requestDataExport} variant="outline">
            Download My Data
          </Button>
          <Button onClick={deleteAccount} variant="destructive">
            Delete My Account
          </Button>
        </div>
      </div>
    </div>
  )
}
```

---

**Next Steps**: Review `compliance.md` for regulatory compliance details and `authentication.md` for additional security measures.