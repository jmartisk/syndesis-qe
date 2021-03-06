# @sustainer: avano@redhat.com

@integration-sf-producers

Feature: Integration - SalesForce producers
  Background:
    Given clean SF, removes all leads with email: "jdoeprod@acme.com,joedoeprod@acme.com"
      And deploy AMQ broker and add accounts
      And clean destination type "queue" with name "sf-producers-input"
      And clean destination type "queue" with name "sf-producers-output"
      And create AMQ connection
      And create SF connection
      And create SF lead with first name: "John", last name: "Doe", email: "jdoeprod@acme.com" and company: "ACME"
      And create AMQ "subscribe" action step with destination type "queue" and destination name "sf-producers-input"

  @integration-sf-producers-delete-record
  Scenario: Delete record
    When create SF "delete-sobject" action step on field: "Lead"
      And create integration with name: "AMQ-SF delete record"
    Then wait for integration with name: "AMQ-SF delete record" to become active
    When publish message with content '{"Id":"LEAD_ID"}' to queue "sf-producers-input"
    Then verify that lead was deleted

  @integration-sf-producers-delete-record-external-id
  Scenario: Delete record with external id
    When create SF "delete-sobject-with-id" action step with properties
      | sObjectName   | Lead  |
      | sObjectIdName | Email |
      And create integration with name: "AMQ-SF delete record with external id"
    Then wait for integration with name: "AMQ-SF delete record with external id" to become active
    When publish message with content '{"Id":"jdoeprod@acme.com"}' to queue "sf-producers-input"
    Then verify that lead was deleted

  @integration-sf-producers-fetch-record
  Scenario: Fetch record
    When create SF "get-sobject" action step on field: "Lead"
      And create AMQ "publish" action step with destination type "queue" and destination name "sf-producers-output"
      And create integration with name: "AMQ-SF-AMQ fetch record"
    Then wait for integration with name: "AMQ-SF-AMQ fetch record" to become active
    When publish message with content '{"Id":"LEAD_ID"}' to queue "sf-producers-input"
    Then verify that lead json object was received from queue "sf-producers-output"

  @integration-sf-producers-fetch-record-external-id
  Scenario: Fetch record with external id
    When create SF "get-sobject-with-id" action step with properties
      | sObjectName   | Lead  |
      | sObjectIdName | Email |
      And create AMQ "publish" action step with destination type "queue" and destination name "sf-producers-output"
      And create integration with name: "AMQ-SF-AMQ fetch record with external id"
    Then wait for integration with name: "AMQ-SF-AMQ fetch record with external id" to become active
    When publish message with content '{"Id":"jdoeprod@acme.com"}' to queue "sf-producers-input"
    Then verify that lead json object was received from queue "sf-producers-output"

  @integration-sf-producers-create-record
  Scenario: Create a new record
    When create SF "create-sobject" action step on field: "Lead"
      And start mapper definition with name: "integration-sf-producers-create-record"
      And MAP using Step 2 and field "id" to "/id"
      And create AMQ "publish" action step with destination type "queue" and destination name "sf-producers-output" with datashape type "JSON_INSTANCE" and specification '{"id":"abc"}'
      And create integration with name: "AMQ-SF-AMQ new record"
    Then wait for integration with name: "AMQ-SF-AMQ new record" to become active
    When publish message with content '{"FirstName":"Joe", "LastName":"Doe","Email":"joedoeprod@acme.com","Company":"XYZ"}' to queue "sf-producers-input"
    Then verify that lead with email "joedoeprod@acme.com" was created
      And verify that lead creation response with email "joedoeprod@acme.com" was received from queue "sf-producers-output"

  @integration-sf-producers-update-record
  Scenario: Update record
    When create SF "update-sobject" action step on field: "Lead"
      And create integration with name: "AMQ-SF update record"
    Then wait for integration with name: "AMQ-SF update record" to become active
    When publish message with content '{"Id":"LEAD_ID", "Email":"joedoeprod@acme.com"}' to queue "sf-producers-input"
    Then verify that leads email was updated to "joedoeprod@acme.com"

  @integration-sf-producers-upsert-record-insert
  Scenario: Upsert record - insert
    When create SF "upsert-sobject" action step with properties
      | sObjectName   | Lead  |
      | sObjectIdName | Email |
      And start mapper definition with name: "integration-sf-producers-upsert-record-insert"
      And MAP using Step 2 and field "id" to "/id"
      And create AMQ "publish" action step with destination type "queue" and destination name "sf-producers-output" with datashape type "JSON_INSTANCE" and specification '{"id":"abc"}'
      And create integration with name: "AMQ-SF-AMQ upsert insert record"
    Then wait for integration with name: "AMQ-SF-AMQ upsert insert record" to become active
    # This user does not exist, will be created
    When publish message with content '{"Email":"joedoeprod@acme.com", "Firstname":"Joe", "Lastname":"Doe", "Company":"XYZ"}' to queue "sf-producers-input"
    Then verify that lead with email "joedoeprod@acme.com" was created
      And verify that lead creation response with email "joedoeprod@acme.com" was received from queue "sf-producers-output"

  @integration-sf-producers-upsert-record-update
  Scenario: Upsert record - update
    When create SF "upsert-sobject" action step with properties
      | sObjectName    | Lead  |
      | sObjectIdName  | Email |
      And create AMQ "publish" action step with destination type "queue" and destination name "sf-producers-output"
      And create integration with name: "AMQ-SF-AMQ upsert update record"
    Then wait for integration with name: "AMQ-SF-AMQ upsert update record" to become active
    # This user does exist, but with first name John
    When publish message with content '{"Email":"jdoeprod@acme.com", "Firstname":"Joe", "Lastname":"Doe", "Company":"XYZ"}' to queue "sf-producers-input"
    Then verify that lead name was updated
