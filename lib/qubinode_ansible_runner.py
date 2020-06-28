import ansible_runner
import os
from ansible_vault import Vault
import argparse
import os.path
from os import path

#vault = Vault('xXxXxXxXx')
#data = vault.load(open('env/passwords').read())

def run_playbook(data_path, playbook_path, verbose, destroy):
  if verbose:
    level=3
  else:
    level=1

  r = ansible_runner.run(private_data_dir=data_path, playbook=playbook_path,verbosity=level, extravars={'vm_teardown': destroy})
  print("{}: {}".format(r.status, r.rc))
  # successful: 0
  if verbose:
    for each_host_event in r.events:
      print(each_host_event['event'])
  print("Final status:")
  print(r.stats)

def main():
  # Creating the parser
  parse_item = argparse.ArgumentParser(description='Run ansible playbooks using ansible runner')
  parse_item.add_argument('PlaybookName',
                       metavar='playbook',
                       type=str,
                       help='Enter the playbook name. Example rhel.yml')
  parse_item.add_argument('-d',
                       '--destroy',
                       action='store_true',
                       help='set if you would like to destroy enviornment.')
  parse_item.add_argument('-v',
                       '--verbose',
                       action='store_true',
                       help='Set Verbosity of ansible playbook')

  # Execute the parse_args() method
  args = parse_item.parse_args()

  playbookname = args.PlaybookName

  print(args)
  print(playbookname)
  cwd = os.getcwd()
  print ("File exists:"+str(path.exists(cwd+'/project/'+playbookname)))
  run_playbook(cwd, playbookname, args.verbose, args.destroy)

if __name__== "__main__":
   main()

