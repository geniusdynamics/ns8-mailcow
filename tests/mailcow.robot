*** Settings ***
Library    SSHLibrary

*** Variables ***
${HOST}    mailcow.example.org
${ADMIN_USER}    admin
${ADMIN_PASSWORD}    Nethesis,1234
${module_id}    ${EMPTY}

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

*** Test Cases ***
Check if mailcow is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${module_id}    ${output.module_id}

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
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"host":"${HOST}","http2https":true,"lets_encrypt":false}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if mailcow configuration reads back
    ${output}  ${rc} =    Execute Command    api-cli run module/${module_id}/get-configuration
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{config} =    Evaluate    json.loads($output)    modules=json
    Should Be Equal    ${config.host}    ${HOST}

Check if mailcow works as expected
    Wait Until Keyword Succeeds    15 min    10 sec    Mailcow UI answers

Check if mailcow is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
