pipeline {
  agent any

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '20', artifactNumToKeepStr: '5'))
    disableConcurrentBuilds(abortPrevious: true)
    skipDefaultCheckout(true)
  }

  environment {
    CI = 'true'
  }

  stages {
    stage('Info') {
      steps {
        dir('/workspace') {
          sh '''
            echo "NODE: $(node -v 2>/dev/null || true)"
            echo "NPM:  $(npm -v 2>/dev/null || true)"
            echo "PWD:  $(pwd)"
            test -f Jenkinsfile && echo "Jenkinsfile: OK" || echo "Jenkinsfile: MISSING"
          '''
        }
      }
    }

    stage('Backend install') {
      steps {
        dir('/workspace/backend') {
          sh 'npm ci'
        }
      }
    }

    stage('Backend smoke') {
      steps {
        dir('/workspace/backend') {
          sh 'node --check src/index.js'
        }
      }
    }

    stage('Frontend install + build') {
      steps {
        dir('/workspace/frontend') {
          sh 'npm ci'
          sh 'npm run build'
        }
      }
    }

    stage('Compose validate (optional)') {
      when {
        expression { return new File('/workspace/docker-compose.secure.yml').exists() }
      }
      steps {
        dir('/workspace') {
          sh '''
            if command -v docker >/dev/null 2>&1; then
              docker compose -f docker-compose.secure.yml config >/dev/null && echo "docker-compose.secure.yml: OK"
            else
              echo "Docker CLI not in agent — skip compose validate"
            fi
          '''
        }
      }
    }

    stage('Archive frontend dist') {
      when {
        expression { return new File('/workspace/frontend/dist').exists() }
      }
      steps {
        sh '''
          rm -rf "${WORKSPACE}/artifacts" && mkdir -p "${WORKSPACE}/artifacts"
          cp -a /workspace/frontend/dist "${WORKSPACE}/artifacts/"
        '''
        archiveArtifacts artifacts: 'artifacts/dist/**/*', fingerprint: true
      }
    }
  }

  post {
    failure {
      echo 'Pipeline failed — проверьте логи стадий выше.'
    }
  }
}
