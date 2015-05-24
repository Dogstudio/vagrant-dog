<?php
namespace Commands;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;

class EmulsionCommand extends Command
{
    protected $rootPath;

    protected function configure()
    {
        $this->setName('emulsion:clone')
            ->setDescription('Get Emulsion source from Gitlab');
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $output->writeln('Get Emulsion sources...');
    }

    // ========================================================================

    protected function prepareStructure()
    {

    }
}