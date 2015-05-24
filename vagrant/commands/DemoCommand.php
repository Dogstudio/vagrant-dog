<?php
namespace Commands;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;

class DemoCommand extends Command
{
    protected function configure()
    {
        $this->setName('demo:greet')
            ->setDescription('Saluez quelqu\'un')
            ->addArgument('name', InputArgument::OPTIONAL, 'Qui voulez-vous saluez?')
            ->addOption('yell', null, InputOption::VALUE_NONE, 'Si défini, la réponse est affichée en majuscules');
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $name = $input->getArgument('name') 
            ? 'Salut, ' . $name
            : 'Salut !';

        if ($input->getOption('yell')) {
            $text = strtoupper($text);
        }

        $output->writeln($text);
    }
}