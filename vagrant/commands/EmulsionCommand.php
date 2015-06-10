<?php
namespace Commands;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Process\Process;

class EmulsionCommand extends Command
{
    protected $rootPath;

    protected function configure()
    {
        $this->setName('emulsion:clone')
            ->setDescription('Get Emulsion source from Gitlab');
    }

    protected function initialize(InputInterface $input, OutputInterface $output)
    {
        $this->rootPath = realpath(__DIR__ . '/../../');
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $this->downloadEmulsionSources($input, $output);
    }

    // ========================================================================

    protected function downloadEmulsionSources(InputInterface $input, OutputInterface $output)
    {
        $process = new Process('cd ' . $this->rootPath . '/public_tmp ; git archive --remote git@gitlab.dogstudio.be:dogstudio/emulsion.git master | tar -x -C ./');
        $process->setTimeout(3600)->run();

        if (!$process->isSuccessful()) {
            throw new \RuntimeException($process->getErrorOutput());
        }

        $output->write($process->getOutput());
    }
}
