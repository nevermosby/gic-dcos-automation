# 项目功能：DCOS + 首都在线GIC + Ansible = Automation for DCOS deployment

自动化部署[DCOS](https://dcos.io/)到[首都在线GIC云环境](https://www.capitalonline.net/zh-cn/service/cloud/quanqiuyunjisuanfuwuqiGIC/)

# 如何使用

```shell
   cd playbook
   ansible-playbook playbook.yml
```

# 如何工作
### 背景
能够自动部署一套DCOS平台，对云服务提供商来说，可以吸引更多的用户来使用自己的产品。这个项目基于首都在线GIC服务，实现一套自动部署DCOS平台solution。

**这是一个48小时内完成的hack project！！！**

**首都在线GIC+DCOS，历史上第一次碰撞从这里开始**

**[Demo Video](http://v.youku.com/v_show/id_XMTU4NjAyMjgxNg==.html)**

### 实现方式
- 利用GIC提供的RESTful API创建多个虚拟机并等待其创建完毕
- 为创建的虚拟机设置SSH登录，使用SSH key，取消密码登录。
- 如有必要，升级操作系统内核
- 安装Docker Engine
- 选取一台虚拟机，作为DCOS boot node，准备安装文件
- 通过DCOS boot node安装DCOS平台

### 如何使用
整个自动化流程是通过Ansible实现，所以trigger一次自动化部署，需要有一台可以运行ansible-playbook的host，命令为：
```shell
# playbook.yml is the magic book
ansible-playbook playbook.yml
```

整个过程需要10分钟左右（根据网络带宽决定），然后你就可以enjoy DCOS了！！！
![dcos-dashboard](https://raw.githubusercontent.com/summerQLin/recommender/master/images/dcos-dashboard.PNG)

### 重点难点
- 调用首都在线GIC的RESTful API创建完虚拟机后，需要获取虚拟机的公网和私网IP地址
  - 公网地址用来SSH登录
  - 私网地址用在DCOS的部署配置文件当中

公网地址是通过分析拿到的VM list的JSON数据，结合Ansible add_host和with模块来直接生成动态的hosts：
```yaml
- add_host: name={{ item.1.ip }} groups=dcos-node-public ansible_user=root ansible_ssh_pass={{ SSH_PWD }} ansible_ssh_private_key_file={{ private_key_file }}
  when: item.0.name.find('dcos-node') != -1 and item.1.type == 'public'
  with_subelements:
    - "{{vm_list}}"
    - netcard
```

私网地址需要分别分配给DCOS master和DCOS agent使用，由于时间有限，目前写了个python小程序来实现，将来会改成纯Ansible模块实现：
```python
m_a_node=[]                                            
m_node=[]                                              
a_node=[]                                              
                                                       
for vm in data["data"][0]["vms"]:                      
    vm_name = vm["name"]                               
    #print vm_name                                     
    if prefix in vm_name and vm_name != boot_node_name:
        # find the target node list                    
        for netcard in vm["netcard"]:                  
            if netcard["type"] == "private":           
                #print netcard["ip"]                   
                m_a_node.append(netcard["ip"])         
                                                       
m_a_node.sort()                                        
m_node=m_a_node[:1]                                    
n_node=m_a_node[1:]
```

- 需要部署DCOS的虚拟机，必须是要能通过ssh key登录的，目前首都在线GIC在创建虚拟机的时候，只能填写登录密码，不提供private key选项。所以通过API创建完虚拟机后，需要设置登录选项: 添加public key，禁止密码登录，更安全。
```yaml
- name: add ssh public key
  authorized_key: user=root key="{{ lookup('file', './files/key.pub') }}"
  register: add_ssh_public_key_result

- name: Disallow password authentication
  lineinfile: dest=/etc/ssh/sshd_config
              regexp="^PasswordAuthentication"
              line="PasswordAuthentication no"
              state=present
  notify:
  - reload sshd service
```

- 因为DCOS需要centos7.2的系统，目前首都在线GIC只提供centos7.1。所以，需要升级操作系统centos7.1的内核。yum upgrade后需要reboot机器，通过ansible的wait_for模块来等待虚拟机恢复登录。
```yaml
- name: Restart server
  command: shutdown -r now "Reboot triggered by Ansible"
  async: 1
  poll: 0
  ignore_errors: true
- name: Wait for server to back online
  local_action:
    wait_for
      host={{ inventory_hostname }}
      state=started
      delay=30
      timeout=600
  sudo: false
```

- centos下安装docker engine，推荐使用overlayfs作为storage driver，而默认的是DeviceMapper，所以安装Docker时，需要设置启动参数,通过Ansible的template模块实现：
```yaml
- name: create Docker configuration directory
  file:
    path: /etc/systemd/system/docker.service.d
    state: directory
    mode: u=rwx,go=rx

- name: install Docker Engine settings
  template:
    src: "{{item}}"
    dest: /etc/systemd/system/docker.service.d
  notify:
    - reload systemctl daemon
    - restart docker daemon
  with_items:
    - docker.conf # its content is like "ExecStart=/usr/bin/docker daemon --storage-driver=overlay -H fd://"
```

### TODO
- integrate DCOS CLI tool
- improve code quality
- maintain


更多内容请查看[这里](https://github.com/nevermosby/gic-dcos-automation/wiki/%23Shanghai%23-Container-Hack-Day#%E4%BD%9C%E5%93%812-dcos--%E9%A6%96%E9%83%BD%E5%9C%A8%E7%BA%BFgic--ansible--automation-for-dcos-deployment)

