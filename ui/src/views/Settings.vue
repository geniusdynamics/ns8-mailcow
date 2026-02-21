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
            <cv-text-input
              :label="$t('settings.mailcow_fqdn')"
              placeholder="mailcow.example.org"
              v-model.trim="host"
              class="mg-bottom"
              :invalid-message="$t(error.host)"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="host"
            >
            </cv-text-input>
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
            <!-- advanced options -->
            <cv-accordion ref="accordion" class="maxwidth mg-bottom">
              <!-- Time Settings -->
              <cv-accordion-item :open="toggleAccordion[0]">
                <template slot="title">{{
                  $t("settings.time_settings")
                }}</template>
                <template slot="content">
                  <cv-text-input
                    :label="$t('settings.timezone')"
                    v-model.trim="TZ"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                  </cv-text-input>
                </template>
              </cv-accordion-item>
              <!-- Network Settings -->
              <cv-accordion-item :open="toggleAccordion[1]">
                <template slot="title">{{
                  $t("settings.network_settings")
                }}</template>
                <template slot="content">
                  <cv-text-input
                    :label="$t('settings.ipv4_network')"
                    v-model.trim="IPV4_NETWORK"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    placeholder="172.22.1"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.ipv6_network')"
                    v-model.trim="IPV6_NETWORK"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    placeholder="fd4d:6169:6c63:6f77::/64"
                  >
                  </cv-text-input>
                  <cv-toggle
                    :value="ENABLE_IPV6"
                    :label="$t('settings.enable_ipv6')"
                    v-model="isEnableIpv6"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                </template>
              </cv-accordion-item>
              <!-- Service Skipping -->
              <cv-accordion-item :open="toggleAccordion[2]">
                <template slot="title">{{
                  $t("settings.service_skipping")
                }}</template>
                <template slot="content">
                  <cv-toggle
                    :value="SKIP_SOGO"
                    :label="$t('settings.skip_sogo')"
                    v-model="isSkipSogo"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
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
                    :value="SKIP_CLAMD"
                    :label="$t('settings.skip_clamd')"
                    v-model="isSkipClamd"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
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
                    :value="SKIP_RSPAMD"
                    :label="$t('settings.skip_rspamd')"
                    v-model="isSkipRspamd"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
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
                    :value="SKIP_LETS_ENCRYPT"
                    :label="$t('settings.skip_lets_encrypt')"
                    v-model="isSkipLetsEncrypt"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
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
                    :value="SKIP_FTS"
                    :label="$t('settings.skip_fts')"
                    v-model="isSkipFts"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
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
                    :value="SKIP_OLEFY"
                    :label="$t('settings.skip_olefy')"
                    v-model="isSkipOlefy"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                </template>
              </cv-accordion-item>
              <!-- Ports Configuration -->
              <cv-accordion-item :open="toggleAccordion[3]">
                <template slot="title">{{
                  $t("settings.ports_configuration")
                }}</template>
                <template slot="content">
                  <cv-text-input
                    :label="$t('settings.http_port')"
                    v-model.number="HTTP_PORT"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.https_port')"
                    v-model.number="HTTPS_PORT"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.smtp_port')"
                    v-model.number="SMTP_PORT"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.smtps_port')"
                    v-model.number="SMTPS_PORT"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.submission_port')"
                    v-model.number="SUBMISSION_PORT"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.imap_port')"
                    v-model.number="IMAP_PORT"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.imaps_port')"
                    v-model.number="IMAPS_PORT"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.pop_port')"
                    v-model.number="POP_PORT"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.pops_port')"
                    v-model.number="POPS_PORT"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.sieve_port')"
                    v-model.number="SIEVE_PORT"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                </template>
              </cv-accordion-item>
              <!-- Security Settings -->
              <cv-accordion-item :open="toggleAccordion[4]">
                <template slot="title">{{
                  $t("settings.security_settings")
                }}</template>
                <template slot="content">
                  <cv-select
                    :label="$t('settings.mailcow_pass_scheme')"
                    v-model="MAILCOW_PASS_SCHEME"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                    <cv-select-option value="BLF-CRYPT"
                      >BLF-CRYPT</cv-select-option
                    >
                    <cv-select-option value="ARGON2">ARGON2</cv-select-option>
                    <cv-select-option value="SHA512">SHA512</cv-select-option>
                    <cv-select-option value="SHA256">SHA256</cv-select-option>
                    <cv-select-option value="MD5">MD5</cv-select-option>
                  </cv-select>
                  <cv-toggle
                    :value="MASTER"
                    :label="$t('settings.master')"
                    v-model="isMaster"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
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
                    :value="ALLOW_ADMIN_EMAIL_LOGIN"
                    :label="$t('settings.allow_admin_email_login')"
                    v-model="isAllowAdminEmailLogin"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <cv-select
                    :label="$t('settings.acl_anyone')"
                    v-model="ACL_ANYONE"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                    <cv-select-option value="disallow"
                      >disallow</cv-select-option
                    >
                    <cv-select-option value="allow">allow</cv-select-option>
                  </cv-select>
                </template>
              </cv-accordion-item>
              <!-- Logging -->
              <cv-accordion-item :open="toggleAccordion[5]">
                <template slot="title">{{ $t("settings.logging") }}</template>
                <template slot="content">
                  <cv-text-input
                    :label="$t('settings.log_lines')"
                    v-model.number="LOG_LINES"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                  <cv-toggle
                    :value="DEV_MODE"
                    :label="$t('settings.dev_mode')"
                    v-model="isDevMode"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                </template>
              </cv-accordion-item>
              <!-- SOGo Settings -->
              <cv-accordion-item :open="toggleAccordion[6]">
                <template slot="title">{{
                  $t("settings.sogo_settings")
                }}</template>
                <template slot="content">
                  <cv-text-input
                    :label="$t('settings.sogo_expire_session')"
                    v-model.number="SOGO_EXPIRE_SESSION"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                </template>
              </cv-accordion-item>
              <!-- Dovecot Settings -->
              <cv-accordion-item :open="toggleAccordion[7]">
                <template slot="title">{{
                  $t("settings.dovecot_settings")
                }}</template>
                <template slot="content">
                  <cv-text-input
                    :label="$t('settings.maildir_gc_time')"
                    v-model.number="MAILDIR_GC_TIME"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.maildir_sub')"
                    v-model.trim="MAILDIR_SUB"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.fts_procs')"
                    v-model.number="FTS_PROCS"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.fts_heap')"
                    v-model.number="FTS_HEAP"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                    type="number"
                  >
                  </cv-text-input>
                </template>
              </cv-accordion-item>
              <!-- ACME Settings -->
              <cv-accordion-item :open="toggleAccordion[8]">
                <template slot="title">{{
                  $t("settings.acme_settings")
                }}</template>
                <template slot="content">
                  <cv-text-input
                    :label="$t('settings.additional_san')"
                    v-model.trim="ADDITIONAL_SAN"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                  </cv-text-input>
                  <cv-toggle
                    :value="LE_STAGING"
                    :label="$t('settings.le_staging')"
                    v-model="isLeStaging"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
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
                    :value="SKIP_IP_CHECK"
                    :label="$t('settings.skip_ip_check')"
                    v-model="isSkipIpCheck"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
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
                    :value="ONLY_MAILCOW_HOSTNAME"
                    :label="$t('settings.only_mailcow_hostname')"
                    v-model="isOnlyMailcowHostname"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <cv-text-input
                    :label="$t('settings.directory_url')"
                    v-model.trim="DIRECTORY_URL"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                  </cv-text-input>
                </template>
              </cv-accordion-item>
              <!-- Netfilter Settings -->
              <cv-accordion-item :open="toggleAccordion[9]">
                <template slot="title">{{
                  $t("settings.netfilter_settings")
                }}</template>
                <template slot="content">
                  <cv-toggle
                    :value="DISABLE_NETFILTER_ISOLATION_RULE"
                    :label="$t('settings.disable_netfilter_isolation_rule')"
                    v-model="isDisableNetfilterIsolationRule"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </cv-toggle>
                  <cv-text-input
                    :label="$t('settings.mailcow_replica_ip')"
                    v-model.trim="MAILCOW_REPLICA_IP"
                    :disabled="
                      loading.getConfiguration || loading.configureModule
                    "
                    class="mg-bottom"
                  >
                  </cv-text-input>
                </template>
              </cv-accordion-item>
            </cv-accordion>
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
      },
      toggleAccordion: [
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
      ],
      // Time Settings
      TZ: "UTC",
      // Network Settings
      IPV4_NETWORK: "172.22.1",
      IPV6_NETWORK: "fd4d:6169:6c63:6f77::/64",
      isEnableIpv6: true,
      // Service Skipping
      isSkipSogo: false,
      isSkipClamd: false,
      isSkipRspamd: false,
      isSkipLetsEncrypt: false,
      isSkipFts: true,
      isSkipOlefy: false,
      // Ports
      HTTP_PORT: 80,
      HTTPS_PORT: 443,
      SMTP_PORT: 25,
      SMTPS_PORT: 465,
      SUBMISSION_PORT: 587,
      IMAP_PORT: 143,
      IMAPS_PORT: 993,
      POP_PORT: 110,
      POPS_PORT: 995,
      SIEVE_PORT: 4190,
      // Security
      MAILCOW_PASS_SCHEME: "BLF-CRYPT",
      isMaster: true,
      isAllowAdminEmailLogin: false,
      ACL_ANYONE: "disallow",
      // Logging
      LOG_LINES: 9999,
      isDevMode: false,
      // SOGo
      SOGO_EXPIRE_SESSION: 480,
      // Dovecot
      MAILDIR_GC_TIME: 7200,
      MAILDIR_SUB: "",
      FTS_PROCS: 3,
      FTS_HEAP: 512,
      // ACME
      ADDITIONAL_SAN: "",
      isLeStaging: false,
      isSkipIpCheck: false,
      isOnlyMailcowHostname: false,
      DIRECTORY_URL: "",
      // Netfilter
      isDisableNetfilterIsolationRule: false,
      MAILCOW_REPLICA_IP: "",
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
      // Time Settings
      this.TZ = config.TZ || "UTC";
      // Network Settings
      this.IPV4_NETWORK = config.IPV4_NETWORK || "172.22.1";
      this.IPV6_NETWORK = config.IPV6_NETWORK || "fd4d:6169:6c63:6f77::/64";
      this.isEnableIpv6 = config.ENABLE_IPV6 !== "false";
      // Service Skipping
      this.isSkipSogo = config.SKIP_SOGO === "y";
      this.isSkipClamd = config.SKIP_CLAMD === "y";
      this.isSkipRspamd = config.SKIP_RSPAMD === "y";
      this.isSkipLetsEncrypt = config.SKIP_LETS_ENCRYPT === "y";
      this.isSkipFts = config.SKIP_FTS === "y";
      this.isSkipOlefy = config.SKIP_OLEFY === "y";
      // Ports
      this.HTTP_PORT = config.HTTP_PORT || 80;
      this.HTTPS_PORT = config.HTTPS_PORT || 443;
      this.SMTP_PORT = config.SMTP_PORT || 25;
      this.SMTPS_PORT = config.SMTPS_PORT || 465;
      this.SUBMISSION_PORT = config.SUBMISSION_PORT || 587;
      this.IMAP_PORT = config.IMAP_PORT || 143;
      this.IMAPS_PORT = config.IMAPS_PORT || 993;
      this.POP_PORT = config.POP_PORT || 110;
      this.POPS_PORT = config.POPS_PORT || 995;
      this.SIEVE_PORT = config.SIEVE_PORT || 4190;
      // Security
      this.MAILCOW_PASS_SCHEME = config.MAILCOW_PASS_SCHEME || "BLF-CRYPT";
      this.isMaster = config.MASTER !== "n";
      this.isAllowAdminEmailLogin = config.ALLOW_ADMIN_EMAIL_LOGIN === "y";
      this.ACL_ANYONE = config.ACL_ANYONE || "disallow";
      // Logging
      this.LOG_LINES = config.LOG_LINES || 9999;
      this.isDevMode = config.DEV_MODE === "y";
      // SOGo
      this.SOGO_EXPIRE_SESSION = config.SOGO_EXPIRE_SESSION || 480;
      // Dovecot
      this.MAILDIR_GC_TIME = config.MAILDIR_GC_TIME || 7200;
      this.MAILDIR_SUB = config.MAILDIR_SUB || "";
      this.FTS_PROCS = config.FTS_PROCS || 3;
      this.FTS_HEAP = config.FTS_HEAP || 512;
      // ACME
      this.ADDITIONAL_SAN = config.ADDITIONAL_SAN || "";
      this.isLeStaging = config.LE_STAGING === "y";
      this.isSkipIpCheck = config.SKIP_IP_CHECK === "y";
      this.isOnlyMailcowHostname = config.ONLY_MAILCOW_HOSTNAME === "y";
      this.DIRECTORY_URL = config.DIRECTORY_URL || "";
      // Netfilter
      this.isDisableNetfilterIsolationRule =
        config.DISABLE_NETFILTER_ISOLATION_RULE === "y";
      this.MAILCOW_REPLICA_IP = config.MAILCOW_REPLICA_IP || "";

      this.loading.getConfiguration = false;
      this.focusElement("host");
    },
    validateConfigureModule() {
      this.clearErrors(this);

      let isValidationOk = true;
      if (!this.host) {
        this.error.host = "common.required";

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
        this.error[param] = this.$t("settings." + validationError.error);

        if (!focusAlreadySet) {
          this.focusElement(param);
          focusAlreadySet = true;
        }
      }
    },
    async configureModule() {
      this.error.test_imap = false;
      this.error.test_smtp = false;
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
            // Time Settings
            TZ: this.TZ,
            // Network Settings
            IPV4_NETWORK: this.IPV4_NETWORK,
            IPV6_NETWORK: this.IPV6_NETWORK,
            ENABLE_IPV6: this.isEnableIpv6 ? "true" : "false",
            // Service Skipping
            SKIP_SOGO: this.isSkipSogo ? "y" : "n",
            SKIP_CLAMD: this.isSkipClamd ? "y" : "n",
            SKIP_RSPAMD: this.isSkipRspamd ? "y" : "n",
            SKIP_LETS_ENCRYPT: this.isSkipLetsEncrypt ? "y" : "n",
            SKIP_FTS: this.isSkipFts ? "y" : "n",
            SKIP_OLEFY: this.isSkipOlefy ? "y" : "n",
            // Ports
            HTTP_PORT: this.HTTP_PORT,
            HTTPS_PORT: this.HTTPS_PORT,
            SMTP_PORT: this.SMTP_PORT,
            SMTPS_PORT: this.SMTPS_PORT,
            SUBMISSION_PORT: this.SUBMISSION_PORT,
            IMAP_PORT: this.IMAP_PORT,
            IMAPS_PORT: this.IMAPS_PORT,
            POP_PORT: this.POP_PORT,
            POPS_PORT: this.POPS_PORT,
            SIEVE_PORT: this.SIEVE_PORT,
            // Security
            MAILCOW_PASS_SCHEME: this.MAILCOW_PASS_SCHEME,
            MASTER: this.isMaster ? "y" : "n",
            ALLOW_ADMIN_EMAIL_LOGIN: this.isAllowAdminEmailLogin ? "y" : "n",
            ACL_ANYONE: this.ACL_ANYONE,
            // Logging
            LOG_LINES: this.LOG_LINES,
            DEV_MODE: this.isDevMode ? "y" : "n",
            // SOGo
            SOGO_EXPIRE_SESSION: this.SOGO_EXPIRE_SESSION,
            // Dovecot
            MAILDIR_GC_TIME: this.MAILDIR_GC_TIME,
            MAILDIR_SUB: this.MAILDIR_SUB,
            FTS_PROCS: this.FTS_PROCS,
            FTS_HEAP: this.FTS_HEAP,
            // ACME
            ADDITIONAL_SAN: this.ADDITIONAL_SAN,
            LE_STAGING: this.isLeStaging ? "y" : "n",
            SKIP_IP_CHECK: this.isSkipIpCheck ? "y" : "n",
            ONLY_MAILCOW_HOSTNAME: this.isOnlyMailcowHostname ? "y" : "n",
            DIRECTORY_URL: this.DIRECTORY_URL,
            // Netfilter
            DISABLE_NETFILTER_ISOLATION_RULE: this
              .isDisableNetfilterIsolationRule
              ? "y"
              : "n",
            MAILCOW_REPLICA_IP: this.MAILCOW_REPLICA_IP,
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
</style>
