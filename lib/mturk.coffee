mturkAPI = undefined

if not TurkServer.config.mturk.accessKeyId or not TurkServer.config.mturk.secretAccessKey
  Meteor._debug "Missing Amazon API keys for connecting to MTurk. Please configure."
else
  settings =
    sandbox: TurkServer.config.mturk.sandbox
    creds:
      accessKey: TurkServer.config.mturk.accessKeyId
      secretKey: TurkServer.config.mturk.secretAccessKey

  mturkAPI = mturkModule.exports(settings)

TurkServer.mturk = (op, params) ->
  unless mturkAPI
    console.log "Ignoring operation " + op + " because MTurk is not configured."
    return
  throw new Error("undefined mturk operation") unless mturkAPI[op]
  syncFunc = Meteor._wrapAsync mturkAPI[op].bind mturkAPI
  return syncFunc(params)

TurkServer.Util ?= {}

# Assign a qualification and store it in the workers collection
TurkServer.Util.assignQualification = (workerId, qualId) ->
  TurkServer.mturk "AssignQualification",
    WorkerId: workerId
    QualificationTypeId: qualId

  # Update worker collection if succeeded (no throw)
  Workers.update workerId,
    $push:
      quals: {
        id: qualId
        value: 1
      }
  return

# Initialize some helpful qualifications
Meteor.startup ->
  # US Worker
  Qualifications.upsert { name: "US Worker" },
    $set:
      QualificationTypeId: "00000000000000000071"
      Comparator: "EqualTo"
      LocaleValue: "US"

  # US or CA worker
  Qualifications.upsert { name: "US or CA Worker" },
    $set:
      QualificationTypeId: "00000000000000000071"
      Comparator: "In"
      LocaleValue: ["US", "CA"]

  # 100 HITs
  Qualifications.upsert { name: "> 100 HITs" },
    $set:
      QualificationTypeId: "00000000000000000040"
      Comparator: "GreaterThan"
      IntegerValue: "100"

  # 95% Approval
  Qualifications.upsert { name: "95% Approval" },
    $set:
      QualificationTypeId: "000000000000000000L0"
      Comparator: "GreaterThanOrEqualTo"
      IntegerValue: "95"

  # Adult Worker
  Qualifications.upsert { name: "Adult Worker" },
    $set:
      QualificationTypeId: "00000000000000000060"
      Comparator: "EqualTo"
      IntegerValue: "1"
