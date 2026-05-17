name: macm-ihd-java-service-demo

on:
  workflow_call:
    inputs: 
      SAST_SCAN:
        required: false 
        type: boolean
      SCA_SCAN:
        required: false 
        type: boolean
      CONTAINER_SCAN:
        required: false 
        type: boolean
      IAC_SCAN:
        required: false 
        type: boolean
      CONTAINER_BUILD:
        required: false 
        type: boolean
      AWS_REGION:
        required: false
        type: string
      CLUSTER_NAME:
        required: false
        type: string
      NAMESPACE:
        required: true
        type: string
      DEPLOY:
        required: false
        type: boolean
        default: false
      roleArn:
        required: false
        type: string
      ecr:
        required: false
        type: string
      ecr_repo_name:
        required: false
        type: string
      ENVIRONMENT:
        required: false
        type: string
      SNYK_ORG:
        required: false
        type: string
        default: "macm-infra"
      CF_INVALIDATE_CACHE:
        required: false
        type: boolean
        default: false
      CF_ROLEARN:
        required: false
        type: string
      CF_DISTRIBUTION_ID:
        required: false
        type: string
    secrets:
      DOCKER_USERNAME:
        required: false
      DOCKER_PASSWORD:
        required: false
      AWS_ACCESS_KEY_ID:
        required: false
      AWS_SECRET_ACCESS_KEY:
        required: false
      SNYK_TOKEN: 
        required: false
      GUARDIAN_TOKEN:
        required: false

env:
  BRANCH: ${{ github.ref_name }}
  COMMIT_ID: $(git rev-parse HEAD)
  SERVICE_NAME: ${{ github.event.repository.name }}
  GUARDIAN_URL: guard.mirae-asset.co.in:8289
  GIT_HASH: $(git rev-parse --short "$GITHUB_SHA")
  ENVIRONMENT: ${{ inputs.ENVIRONMENT }}
  roleArn_uat: ${{ vars.ROLEARN_UAT }}
  docker_baseimg_ecr: ${{ vars.ECR_UAT }}

jobs:
  sast-scan:
    if: inputs.SAST_SCAN == true
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: SAST Scan [DRY-RUN]
        shell: bash
        run: |-
          echo "[DRY-RUN] Starting SAST Scan..."
          GUARDIAN_SERVICE_NAME=$(echo ${{ env.SERVICE_NAME }} | sed 's/_/-/g')
          echo "GUARDIAN_SERVICE_NAME=$GUARDIAN_SERVICE_NAME" >> $GITHUB_ENV
          echo "[DRY-RUN] GUARDIAN_SERVICE_NAME resolved to: $GUARDIAN_SERVICE_NAME"
          echo "[DRY-RUN] Would run: semgrep scan --json > ${{ env.SERVICE_NAME }}-sast.json"
          echo "[DRY-RUN] Would POST sast.json to Guardian URL: ${{ env.GUARDIAN_URL }}/api/v1/vulnerability"
          echo "[DRY-RUN] integration_id=semgrep_sast | service_name=$GUARDIAN_SERVICE_NAME | branch=${{ env.BRANCH }}"
          echo '{}' > ${{ env.SERVICE_NAME }}-sast.json  # Create dummy report file for artifact upload

      - name: Uploads
        uses: actions/upload-artifact@v4.0.0
        with:
          name: sast-report-${{ env.ENVIRONMENT }}
          path: ${{ env.SERVICE_NAME }}-sast.json

  iac-scan:
    if: inputs.IAC_SCAN == true
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: IAC Scan [DRY-RUN]
        shell: bash
        run: |-
          echo "[DRY-RUN] Would run: trivy config scan (scan-type=config, format=json)"
          echo "[DRY-RUN] Output would be saved to: ${{ env.SERVICE_NAME }}-iac.json"
          echo '{}' > ${{ env.SERVICE_NAME }}-iac.json  # Create dummy report file

      - name: IAC Scan API [DRY-RUN]
        shell: bash
        run: |-
          GUARDIAN_SERVICE_NAME=$(echo ${{ env.SERVICE_NAME }} | sed 's/_/-/g')
          echo "GUARDIAN_SERVICE_NAME=$GUARDIAN_SERVICE_NAME" >> $GITHUB_ENV
          echo "[DRY-RUN] GUARDIAN_SERVICE_NAME resolved to: $GUARDIAN_SERVICE_NAME"
          echo "[DRY-RUN] Would POST iac.json to Guardian URL: ${{ env.GUARDIAN_URL }}/api/v1/vulnerability"
          echo "[DRY-RUN] integration_id=trivy_iac | service_name=$GUARDIAN_SERVICE_NAME"

      - name: Uploads
        uses: actions/upload-artifact@v4.0.0
        with:
          name: iac-report-${{ env.ENVIRONMENT }}
          path: ${{ env.SERVICE_NAME }}-iac.json

  app-build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up JDK 21 (Attempt 1) [DRY-RUN]
        id: setup_java_1
        shell: bash
        run: echo "[DRY-RUN] Would run: actions/setup-java@v4 with java-version=21, distribution=oracle (Attempt 1)"
        continue-on-error: true

      - name: Set up JDK 21 (Attempt 2) [DRY-RUN]
        if: steps.setup_java_1.outcome == 'failure'
        id: setup_java_2
        shell: bash
        run: echo "[DRY-RUN] Would run: actions/setup-java@v4 with java-version=21, distribution=oracle (Attempt 2)"
        continue-on-error: true

      - name: Set up JDK 21 (Attempt 3) [DRY-RUN]
        if: steps.setup_java_2.outcome == 'failure'
        id: setup_java_3
        shell: bash
        run: echo "[DRY-RUN] Would run: actions/setup-java@v4 with java-version=21, distribution=oracle (Attempt 3)"
        continue-on-error: true

      - name: Set up JDK 21 (Attempt 4) [DRY-RUN]
        if: steps.setup_java_3.outcome == 'failure'
        id: setup_java_4
        shell: bash
        run: echo "[DRY-RUN] Would run: actions/setup-java@v4 with java-version=21, distribution=oracle (Attempt 4)"
        continue-on-error: true

      - name: Set up JDK 21 (Attempt 5) [DRY-RUN]
        if: steps.setup_java_4.outcome == 'failure'
        shell: bash
        run: echo "[DRY-RUN] Would run: actions/setup-java@v4 with java-version=21, distribution=oracle (Attempt 5)"

      - name: Build with Maven [DRY-RUN]
        shell: bash
        run: |-
          echo "[DRY-RUN] Would run: mvn clean install -Dmaven.test.skip=true"
          mkdir -p target
          echo "dummy-artifact" > target/demo-app.jar  # Create dummy jar for artifact upload

      - name: Uploads
        uses: actions/upload-artifact@v4.0.0
        with:
          name: artifact-${{ env.ENVIRONMENT }}
          path: target/*.jar

  sca-scan:
    if: inputs.SCA_SCAN == true
    runs-on: ubuntu-latest
    needs: [app-build, iac-scan, sast-scan]
    steps:
      - uses: actions/checkout@v4

      - name: Download Artifact if exists
        uses: actions/download-artifact@v4.1.0
        with:
          name: artifact-${{ env.ENVIRONMENT }}
          path: build/

      - name: SCA Scan [DRY-RUN]
        shell: bash
        run: |-
          GUARDIAN_SERVICE_NAME=$(echo ${{ env.SERVICE_NAME }} | sed 's/_/-/g')
          echo "GUARDIAN_SERVICE_NAME=$GUARDIAN_SERVICE_NAME" >> $GITHUB_ENV
          echo "[DRY-RUN] GUARDIAN_SERVICE_NAME resolved to: $GUARDIAN_SERVICE_NAME"
          echo "[DRY-RUN] Would run: snyk auth <SNYK_TOKEN>"
          echo "[DRY-RUN] Would run: snyk config set org=${{ inputs.SNYK_ORG }}"
          echo "[DRY-RUN] Would run: snyk test --json-file-output=${{ env.SERVICE_NAME }}-sca.json"
          echo "[DRY-RUN] Would POST sca.json to Guardian URL: ${{ env.GUARDIAN_URL }}/api/v1/vulnerability"
          echo "[DRY-RUN] integration_id=snyk_sca | service_name=$GUARDIAN_SERVICE_NAME"
          echo '{}' > ${{ env.SERVICE_NAME }}-sca.json  # Create dummy report file

      - name: Uploads
        uses: actions/upload-artifact@v4.0.0
        with:
          name: sca-report-${{ env.ENVIRONMENT }}
          path: ${{ env.SERVICE_NAME }}-sca.json

  container-build-push:
    needs: [app-build]
    if: inputs.CONTAINER_BUILD == true
    runs-on: ubuntu-latest
    env:
      DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: ${{ inputs.AWS_REGION }}
      ecr: ${{ inputs.ecr }}
      roleArn: ${{ inputs.roleArn }}
    steps:
      - uses: actions/checkout@v4

      - name: Docker Hub Login [DRY-RUN]
        shell: bash
        run: echo "[DRY-RUN] Would run: docker login --username <DOCKER_USERNAME> --password-stdin"

      - name: Download Artifact if exists
        uses: actions/download-artifact@v4.1.0
        with:
          name: artifact-${{ env.ENVIRONMENT }}
          path: build/

      - name: Docker Build [DRY-RUN]
        shell: bash
        run: |-
          ecr_repo_name=$(echo ${{ env.SERVICE_NAME }} | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')
          echo "ecr_repo_name=$ecr_repo_name" >> $GITHUB_ENV
          echo "[DRY-RUN] Would assume role: ${{ env.roleArn_uat }}"
          echo "[DRY-RUN] Would run: aws ecr get-login-password | docker login --username AWS ${{ env.docker_baseimg_ecr }}"
          echo "[DRY-RUN] Would run: docker build --build-arg docker_baseimg_ecr=${{ env.docker_baseimg_ecr }} -f deployment-config/Dockerfile -t ${{ inputs.ecr }}/$ecr_repo_name:${{ env.GIT_HASH }} ."

      - name: AWS Login [DRY-RUN]
        shell: bash
        run: |-
          echo "[DRY-RUN] Would assume role: ${{ env.roleArn }}"
          echo "[DRY-RUN] Would export temporary AWS credentials to GITHUB_ENV"

      - name: Image push to ECR [DRY-RUN]
        shell: bash
        run: |-
          echo "[DRY-RUN] Would run: aws ecr get-login-password | docker login --username AWS ${{ inputs.ecr }}"
          echo "[DRY-RUN] Would run: docker push ${{ inputs.ecr }}/$ecr_repo_name:${{ env.GIT_HASH }}"

  container-scan:
    needs: [container-build-push]
    if: inputs.CONTAINER_SCAN == true
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: ${{ inputs.AWS_REGION }}
      ecr: ${{ inputs.ecr }}
      roleArn: ${{ inputs.roleArn }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Container Scan [DRY-RUN]
        shell: bash
        run: |-
          echo "[DRY-RUN] Would assume role: ${{ env.roleArn }}"
          IMAGE_REF=${{ inputs.ecr }}/$(echo ${{ github.event.repository.name }} | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g'):${{ env.GIT_HASH }}
          echo "[DRY-RUN] IMAGE_REF resolved to: $IMAGE_REF"
          echo "[DRY-RUN] Would run: aws ecr get-login-password | docker login ${{ inputs.ecr }}"
          echo "[DRY-RUN] Would run: docker pull $IMAGE_REF"
          echo "[DRY-RUN] Would run: trivy image $IMAGE_REF --format json > ${{ env.SERVICE_NAME }}-container.json"
          echo "[DRY-RUN] Retry logic (max 10 attempts) would be applied around trivy scan"
          echo '{}' > ${{ env.SERVICE_NAME }}-container.json  # Create dummy report file

      - name: Container Scan API [DRY-RUN]
        shell: bash
        run: |-
          GUARDIAN_SERVICE_NAME=$(echo ${{ env.SERVICE_NAME }} | sed 's/_/-/g')
          echo "GUARDIAN_SERVICE_NAME=$GUARDIAN_SERVICE_NAME" >> $GITHUB_ENV
          echo "[DRY-RUN] GUARDIAN_SERVICE_NAME resolved to: $GUARDIAN_SERVICE_NAME"
          echo "[DRY-RUN] Would POST container.json to Guardian URL: ${{ env.GUARDIAN_URL }}/api/v1/vulnerability"
          echo "[DRY-RUN] integration_id=trivy_container | service_name=$GUARDIAN_SERVICE_NAME"

      - name: Uploads
        uses: actions/upload-artifact@v4.0.0
        with:
          name: container-scan-report-${{ env.ENVIRONMENT }}
          path: ${{ env.SERVICE_NAME }}-container.json

  deployment:
    needs: container-build-push
    runs-on: ubuntu-latest
    if: inputs.DEPLOY == true
    environment: ${{ inputs.ENVIRONMENT }}
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: ${{ inputs.AWS_REGION }}
      ecr: ${{ inputs.ecr }}
      roleArn: ${{ inputs.roleArn }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: deploy [DRY-RUN]
        shell: bash
        run: |-
          echo "[DRY-RUN] Would assume role: ${{ env.roleArn }}"
          release=$(echo ${{ github.event.repository.name }} | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')
          echo "[DRY-RUN] Helm release name would be: $release"
          echo "[DRY-RUN] Would run: aws eks update-kubeconfig --name ${{ inputs.CLUSTER_NAME }} --region $AWS_REGION"
          ENVIRONMENT=${{ inputs.ENVIRONMENT }}
          if [[ "$ENVIRONMENT" == "IHD-DEV" ]]; then
            VALUES="dev-values.yaml"; tag=${{ env.GIT_HASH }};
          elif [[ "$ENVIRONMENT" == "IHD-PROD" ]]; then
            VALUES="prod-values.yaml"; tag=${{ env.GIT_HASH }}-uat-verified;
          elif [[ "$ENVIRONMENT" == "IHD-UAT" ]]; then
            VALUES="uat-values.yaml"; tag=${{ env.GIT_HASH }};
          fi
          echo "[DRY-RUN] Selected values file: $VALUES | image tag: $tag"
          echo "[DRY-RUN] Would run: helm upgrade --install --values deployment-config/helm-chart/environment/$VALUES --set image.repository=${{ inputs.ecr }}/$release --set image.tag=$tag --set image.pullPolicy=Always $release deployment-config/helm-chart -n ${{ inputs.NAMESPACE }}"
          echo "[DRY-RUN] Deployment simulation complete."

  cloudfront:
    needs: deployment
    runs-on: ubuntu-latest
    if: ${{ inputs.CF_INVALIDATE_CACHE }}
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: ${{ inputs.AWS_REGION }}
      ecr: ${{ inputs.ecr }}
      roleArn: ${{ inputs.CF_ROLEARN }}
    steps:
      - name: Invalidate Cache [DRY-RUN]
        shell: bash
        run: |-
          echo "[DRY-RUN] Would wait: sleep 60"
          echo "[DRY-RUN] Would assume role: ${{ env.roleArn }}"
          echo "[DRY-RUN] CF_DISTRIBUTION_ID(s): ${{ inputs.CF_DISTRIBUTION_ID }}"
          IFS=',' read -r -a DISTRIBUTION_IDS <<< "${{ inputs.CF_DISTRIBUTION_ID }}"
          for ID in "${DISTRIBUTION_IDS[@]}"; do
            echo "[DRY-RUN] Would run: aws cloudfront create-invalidation --distribution-id $ID --paths '/*'"
          done
          echo "[DRY-RUN] CloudFront cache invalidation simulation complete."
