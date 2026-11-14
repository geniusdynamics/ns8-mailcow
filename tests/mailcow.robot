*** Settings ***
Library    SSHLibrary
Library    String

*** Variables ***
${HOST}    mailcow.example.org
${ADMIN_USER}    admin
${ADMIN_PASSWORD}    Nethesis,1234
${module_id}    ${EMPTY}
${crowdsec_id}    ${EMPTY}
${MAILCHECK}    /root/mailcheck.py

*** Keywords ***
Login to cluster-admin
    New Page    https://${NODE_ADDR}/cluster-admin/
    Fill Text    text="Username"    ${ADMIN_USER}
    Click    button >> text="Continue"
    Fill Text    text="Password"    ${ADMIN_PASSWORD}
    Click    button >> text="Log in"
    Wait For Elements State    css=#main-content    visible    timeout=10s

Mailcow UI answers
    # 2xx, 3xx, 401 and 403 mean the UI answers. 000 (no answer), 404 (no
    # Traefik route), 5xx (for example "Connection to dockerapi container
    # failed") and anything else fail.
    ${status} =    Execute Command    curl -k -s -o /dev/null -w '\%{http_code}' --resolve ${HOST}:443:127.0.0.1 https://${HOST}/
    Should Match Regexp    ${status}    ^(2..|3..|401|403)$    The mailcow UI answered HTTP ${status}
    ${page} =    Execute Command    curl -k -s --resolve ${HOST}:443:127.0.0.1 https://${HOST}/
    Should Contain    ${page}    mail UI

Run on module
    [Arguments]    ${command}
    ${output}    ${rc} =    Execute Command    runagent -m ${module_id} ${command}    return_rc=True
    Should Be Equal As Integers    ${rc}    0    ${command}: ${output}
    RETURN    ${output}

Configure mailcow
    [Arguments]    ${netfilter_mode}
    ${output}    ${err}    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host":"${HOST}","http2https":true,"lets_encrypt":false,"netfilter_mode":"${netfilter_mode}","clamd_enabled":false}'
    ...    return_rc=True    return_stderr=True
    Should Be Equal As Integers    ${rc}    0    configure-module failed: ${output} ${err}

Unit state is
    [Arguments]    ${unit}    ${expected}
    ${state} =    Execute Command    runagent -m ${module_id} systemctl --user is-active ${unit}
    Should Be Equal    ${state}    ${expected}

Server greets
    [Arguments]    ${port}    ${expected}    ${tls}=${EMPTY}
    ${banner}    ${rc} =    Execute Command    python3 ${MAILCHECK} banner 127.0.0.1 ${port} ${tls}    return_rc=True
    Should Be Equal As Integers    ${rc}    0    no answer on port ${port}: ${banner}
    Should Contain    ${banner}    ${expected}

SMTP answers
    Server greets    25    220 ${HOST} ESMTP
    Server greets    587    220 ${HOST} ESMTP

F2B option manage_external is
    [Arguments]    ${expected}
    ${options} =    Run on module    podman exec redis-mailcow-app sh -c 'redis-cli -a "$REDISPASS" --no-auth-warning GET F2B_OPTIONS'
    &{f2b} =    Evaluate    json.loads($options)    modules=json
    Should Be Equal As Integers    ${f2b.manage_external}    ${expected}
    RETURN    ${f2b}

Journal of the node has
    [Arguments]    ${identifier}    ${text}
    ${lines} =    Execute Command    journalctl -q --no-pager -o short SYSLOG_IDENTIFIER=${identifier} --since=-30min | grep -F '${text}' | tail -n 1
    Should Not Be Empty    ${lines}    no "${text}" line from ${identifier} in the journal
    RETURN    ${lines}

CrowdSec has the mailcow parser
    ${output}    ${rc} =    Execute Command    podman exec ${crowdsec_id} cscli parsers inspect geniusdynamics/mailcow-logs    return_rc=True
    Should Be Equal As Integers    ${rc}    0    ${output}

CrowdSec explains
    [Arguments]    ${line}    ${expected}
    # A public address instead of 127.0.0.1, which the whitelist parser skips
    ${line} =    Replace String Using Regexp    ${line}    127\\.0\\.0\\.1    203.0.113.5
    ${output}    ${rc} =    Execute Command    podman exec ${crowdsec_id} cscli explain --type syslog --log '${line}'    return_rc=True
    Should Be Equal As Integers    ${rc}    0    ${output}
    Should Contain    ${output}    ${expected}

*** Test Cases ***
Check if mailcow is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${module_id}    ${output.module_id}
    Put File    ${CURDIR}/mailcheck.py    ${MAILCHECK}

Take screenshots
    [Tags]    ui
    Import Library    Browser
    New Browser    chromium    headless=True
    New Context    ignoreHTTPSErrors=True
    Login to cluster-admin
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}
    Wait For Elements State    iframe >>> h2 >> text="Status"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/1._Status.png
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}?page=settings
    Wait For Elements State    iframe >>> h2 >> text="Settings"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/2._Settings.png
    Close Browser

Check if mailcow can be configured
    Configure mailcow    external

Check if mailcow configuration reads back
    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/get-configuration
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{config} =    Evaluate    json.loads($output)    modules=json
    Should Be Equal    ${config.host}    ${HOST}
    Should Be Equal    ${config.netfilter_mode}    external
    Should Be Equal    ${config.clamd_enabled}    ${False}
    Should Be Equal    ${config.lets_encrypt}    ${False}
    Should Be Equal    ${config.http2https}    ${True}
    Should Not Match Regexp    ${output}    (?i)pass|secret|key    get-configuration returned a secret: ${output}

Check if mailcow works as expected
    Wait Until Keyword Succeeds    15 min    10 sec    Mailcow UI answers

Check if the mail ports are open on the node firewall
    ${service} =    Execute Command    firewall-cmd --info-service=${module_id}
    FOR    ${port}    IN    25    465    587    143    993    110    995    4190
        Should Contain    ${service}    ${port}/tcp
    END

Check if SMTP answers
    Wait Until Keyword Succeeds    20 min    15 sec    SMTP answers
    Server greets    465    220 ${HOST} ESMTP    tls

Check if IMAP answers
    Wait Until Keyword Succeeds    10 min    15 sec    Server greets    143    * OK
    Server greets    993    * OK    tls
    Server greets    110    +OK
    Server greets    4190    "IMPLEMENTATION"

Check if failed logins reach the journal of the node
    ${result} =    Execute Command    python3 ${MAILCHECK} smtp-auth 127.0.0.1 587 nobody@example.org WrongPassword1
    Should Start With    ${result}    rejected
    ${result} =    Execute Command    python3 ${MAILCHECK} imap-login 127.0.0.1 143 nobody@example.org WrongPassword1
    Should Start With    ${result}    rejected
    # Postfix copies its log to /dev/log of the node: the crowdsecurity/postfix
    # collection of NS8 CrowdSec parses these lines
    Wait Until Keyword Succeeds    2 min    5 sec    Journal of the node has    postfix/smtpd    authentication failed
    # Lines of the geniusdynamics/mailcow-logs parser
    Wait Until Keyword Succeeds    2 min    5 sec    Journal of the node has    php-fpm-mailcow-app    MAILCOWAUTH: Login failed for user nobody@example.org

Check netfilter in external mode
    Unit state is    netfilter-mailcow-app.service    active
    &{f2b} =    Wait Until Keyword Succeeds    2 min    5 sec    F2B option manage_external is    1
    # The ban list of "Manage Fail2Ban externally", for the node firewall or CrowdSec
    ${status} =    Execute Command    curl -k -s -o /dev/null -w '\%{http_code}' --resolve ${HOST}:443:127.0.0.1 'https://${HOST}/f2b-banlist.php?id=${f2b.banlist_id}'
    Should Be Equal    ${status}    200
    ${status} =    Execute Command    curl -k -s -o /dev/null -w '\%{http_code}' --resolve ${HOST}:443:127.0.0.1 'https://${HOST}/f2b-banlist.php?id=wrong'
    Should Be Equal    ${status}    404

Check the CrowdSec rules
    [Tags]    crowdsec
    ${output}  ${rc} =    Execute Command    add-module ghcr.io/nethserver/crowdsec:latest 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0    ${output}
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${crowdsec_id}    ${output.module_id}
    ${rc} =    Execute Command    install -m 644 /home/${module_id}/.config/crowdsec/mailcow-logs.yaml /var/lib/nethserver/${crowdsec_id}/state/crowdsec_config/parsers/s01-parse/ && install -m 644 /home/${module_id}/.config/crowdsec/mailcow-bf.yaml /var/lib/nethserver/${crowdsec_id}/state/crowdsec_config/scenarios/ && systemctl reload ${crowdsec_id}
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}  0
    Wait Until Keyword Succeeds    5 min    10 sec    CrowdSec has the mailcow parser
    ${line} =    Journal of the node has    php-fpm-mailcow-app    MAILCOWAUTH: Login failed
    CrowdSec explains    ${line}    geniusdynamics/mailcow-logs
    CrowdSec explains    ${line}    geniusdynamics/mailcow-bf
    ${line} =    Journal of the node has    postfix/smtpd    authentication failed
    CrowdSec explains    ${line}    crowdsecurity/postfix-logs
    [Teardown]    Run Keyword If    '${crowdsec_id}' != ''    Execute Command    remove-module --no-preserve ${crowdsec_id}

Check netfilter in rootful mode
    Configure mailcow    rootful
    Unit state is    netfilter-mailcow-app.service    active
    Wait Until Keyword Succeeds    2 min    5 sec    F2B option manage_external is    0
    # netfilter owns the MAILCOW chain of the pod network namespace
    Wait Until Keyword Succeeds    2 min    5 sec    Run on module    podman exec netfilter-mailcow-app nft list chain ip filter MAILCOW
    SMTP answers

Check netfilter in disabled mode
    Configure mailcow    disabled
    Unit state is    netfilter-mailcow-app.service    inactive
    SMTP answers
    Server greets    143    * OK
    Mailcow UI answers

Check if mailcow is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
