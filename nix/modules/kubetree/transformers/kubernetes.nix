{ self, ... }:
{ lib, config, ... }:
let
  cfg = config.kubetree.kubernetes;
  transform = self.lib.transform;
in
{
  options.kubetree.kubernetes = {
    enable = lib.mkEnableOption "Kubernetes primitives transformers";
  };
  config = lib.mkIf cfg.enable {
    kubetree.transformers = {
      v1 = {
        Pod.spec = rec {
          _transformers = [
            (transform.transformKeyedList {
              keyedListPath = [ "initContainersByName" ];
              keyPath = [ "name" ];
              mergeWithPath = [ "initContainers" ];
            })
            (transform.transformKeyedList {
              keyedListPath = [ "containersByName" ];
              keyPath = [ "name" ];
              mergeWithPath = [ "containers" ];
            })
            (transform.transformKeyedList {
              keyedListPath = [ "volumesByName" ];
              keyPath = [ "name" ];
              mergeWithPath = [ "volumes" ];
            })
          ];
          containers."[]"._transformers = [
            (transform.transformKeyedList {
              keyedListPath = [ "envByName" ];
              keyPath = [ "name" ];
              mergeWithPath = [ "env" ];
              nonAttrKeyPath = [ "value" ];
            })
            (transform.transformKeyedList {
              keyedListPath = [ "portsByName" ];
              keyPath = [ "name" ];
              mergeWithPath = [ "ports" ];
              nonAttrKeyPath = [ "containerPort" ];
            })
            (transform.transformKeyedList {
              keyedListPath = [ "volumeMountsByPath" ];
              keyPath = [ "mountPath" ];
              mergeWithPath = [ "volumeMounts" ];
              nonAttrKeyPath = [ "name" ];
            })
          ];
          initContainers."[]" = containers."[]";
        };
        Service.spec._transformers = [
          (transform.transformKeyedList {
            keyedListPath = [ "portsByName" ];
            keyPath = [ "name" ];
            mergeWithPath = [ "ports" ];
            nonAttrKeyPath = [ "port" ];
          })
        ];
        List.items."[]"._transformers = [ transform.transformResource ];
      };
      apps = {
        Deployment.spec.template = config.kubetree.transformers.v1.Pod;
        DaemonSet.spec.template = config.kubetree.transformers.v1.Pod;
      };
      batch = {
        Job.spec.template = config.kubetree.transformers.v1.Pod;
        CronJob.spec.jobTemplate = config.kubetree.transformers.batch.Job;
      };
    };
  };
}
