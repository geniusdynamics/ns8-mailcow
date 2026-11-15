<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title">
        <h2>{{ $t("settings.title") }}</h2>
      </cv-column>
    </cv-row>
    <cv-row v-if="error.getConfiguration">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-configuration')"
          :description="error.getConfiguration"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="configureModule">
            <NsTextInput
              :label="$t('settings.mail_hostname')"
              placeholder="mail.example.org"
              v-model.trim="host"
              class="mg-bottom maxwidth"
              :invalid-message="error.host"
              :helper-text="$t('settings.mail_hostname_helper')"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="host"
            >
            </NsTextInput>
            <cv-toggle
              value="letsEncrypt"
              :label="$t('settings.lets_encrypt')"
              v-model="isLetsEncryptEnabled"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="mg-bottom"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <cv-toggle
              value="httpToHttps"
              :label="$t('settings.http_to_https')"
              v-model="isHttpToHttpsEnabled"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="mg-bottom"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <cv-toggle
              value="domainCertificates"
              :label="$t('settings.domain_certificates')"
              v-model="isDomainCertificatesEnabled"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="mg-bottom"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <p class="mg-bottom helper maxwidth">
              {{ $t("settings.domain_certificates_helper") }}
            </p>
            <cv-text-area
              :label="$t('settings.additional_names')"
              v-model.trim="additionalNames"
              :helper-text="$t('settings.additional_names_helper')"
              :invalid-message="error.additional_names"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="mg-bottom maxwidth"
              ref="additional_names"
            >
            </cv-text-area>
            <div v-if="certificateNames.length" class="mg-bottom maxwidth">
              <label class="bx--label">{{
                $t("settings.certificate_names")
              }}</label>
              <ul>
                <li v-for="item in certificateNames" :key="item.name">
                  {{ item.name }}:
                  {{ $t("settings.certificate_status_" + item.status) }}
                </li>
              </ul>
            </div>
            <cv-toggle
              value="clamdEnabled"
              :label="$t('settings.clamd_enabled')"
              v-model="isClamdEnabled"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="mg-bottom"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <p class="mg-bottom helper maxwidth">
              {{ $t("settings.clamd_enabled_helper") }}
            </p>
            <label class="bx--label">{{ $t("settings.netfilter_mode") }}</label>
            <cv-radio-group vertical class="mg-bottom maxwidth">
              <cv-radio-button
                :label="$t('settings.netfilter_external')"
                value="external"
                ref="netfilter_mode"
                v-model="netfilterMode"
                :disabled="loading.getConfiguration || loading.configureModule"
              />
              <p class="helper">
                {{ $t("settings.netfilter_external_description") }}
              </p>
              <cv-radio-button
                :label="$t('settings.netfilter_rootful')"
                value="rootful"
                v-model="netfilterMode"
                :disabled="loading.getConfiguration || loading.configureModule"
              />
              <p class="helper">
                {{ $t("settings.netfilter_rootful_description") }}
              </p>
              <cv-radio-button
                :label="$t('settings.netfilter_disabled')"
                value="disabled"
                v-model="netfilterMode"
                :disabled="loading.getConfiguration || loading.configureModule"
              />
              <p class="helper">
                {{ $t("settings.netfilter_disabled_description") }}
              </p>
            </cv-radio-group>
            <NsInlineNotification
              kind="info"
              class="maxwidth"
              :title="$t('settings.mail_ports_title')"
              :description="
                $t('settings.mail_ports_description', {
                  ports: mailPorts.join(', '),
                })
              "
              :showCloseButton="false"
            />
            <cv-row v-if="error.configureModule">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.configure-module')"
                  :description="error.configureModule"
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.configureModule"
              :disabled="loading.getConfiguration || loading.configureModule"
              >{{ $t("settings.save") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import {
  QueryParamService,
  UtilService,
  TaskService,
  IconService,
  PageTitleService,
} from "@nethserver/ns8-ui-lib";

export default {
  name: "Settings",
  mixins: [
    TaskService,
    IconService,
    UtilService,
    QueryParamService,
    PageTitleService,
  ],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "settings",
      },
      urlCheckInterval: null,
      host: "",
      isLetsEncryptEnabled: false,
      isHttpToHttpsEnabled: true,
      isClamdEnabled: true,
      netfilterMode: "external",
      isDomainCertificatesEnabled: false,
      additionalNames: "",
      certificateNames: [],
      mailPorts: [25, 465, 587, 143, 993, 110, 995, 4190],
      loading: {
        getConfiguration: false,
        configureModule: false,
      },
      error: {
        getConfiguration: "",
        configureModule: "",
        host: "",
        lets_encrypt: "",
        http2https: "",
        netfilter_mode: "",
        clamd_enabled: "",
        additional_names: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
  },
  created() {
    this.getConfiguration();
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  methods: {
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.getConfigurationAborted,
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.getConfigurationCompleted,
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
            eventId,
          },
        }),
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
        return;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      const config = taskResult.output;
      this.host = config.host || "";
      this.isLetsEncryptEnabled = config.lets_encrypt || false;
      this.isHttpToHttpsEnabled = config.http2https !== false;
      this.isClamdEnabled = config.clamd_enabled !== false;
      this.netfilterMode = config.netfilter_mode || "external";
      this.isDomainCertificatesEnabled = config.domain_certificates === true;
      this.additionalNames = (config.additional_names || []).join("\n");
      this.certificateNames = config.certificate_names || [];
      if (config.mail_ports) {
        this.mailPorts = config.mail_ports;
      }
      this.loading.getConfiguration = false;
      this.focusElement("host");
    },
    validateConfigureModule() {
      this.clearErrors(this);

      let isValidationOk = true;
      if (!this.host) {
        this.error.host = this.$t("common.required");

        if (isValidationOk) {
          this.focusElement("host");
        }
        isValidationOk = false;
      }
      return isValidationOk;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      let focusAlreadySet = false;

      for (const validationError of validationErrors) {
        const param = validationError.parameter;
        // set i18n error message
        this.error[param] = this.$t("settings." + validationError.error, {
          value: validationError.value,
        });

        if (!focusAlreadySet) {
          this.focusElement(param);
          focusAlreadySet = true;
        }
      }
    },
    async configureModule() {
      const isValidationOk = this.validateConfigureModule();
      if (!isValidationOk) {
        return;
      }

      this.loading.configureModule = true;
      const taskAction = "configure-module";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.configureModuleAborted,
      );

      // register to task validation
      this.core.$root.$once(
        `${taskAction}-validation-failed-${eventId}`,
        this.configureModuleValidationFailed,
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.configureModuleCompleted,
      );
      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: {
            host: this.host,
            lets_encrypt: this.isLetsEncryptEnabled,
            http2https: this.isHttpToHttpsEnabled,
            netfilter_mode: this.netfilterMode,
            clamd_enabled: this.isClamdEnabled,
            domain_certificates: this.isDomainCertificatesEnabled,
            additional_names: this.additionalNames
              .split(/[\s,]+/)
              .map((name) => name.trim().toLowerCase())
              .filter((name) => name),
          },
          extra: {
            title: this.$t("settings.instance_configuration", {
              instance: this.instanceName,
            }),
            description: this.$t("settings.configuring"),
            eventId,
          },
        }),
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
        return;
      }
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;

      // reload configuration
      this.getConfiguration();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
.mg-bottom {
  margin-bottom: $spacing-06;
}

.maxwidth {
  max-width: 38rem;
}

.helper {
  color: $text-02;
  font-size: 0.875rem;
  margin-bottom: $spacing-05;
}
</style>
