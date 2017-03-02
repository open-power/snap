
Benchmark Sponge
================

Description
===========

Sponge enchaîne des calculs de sha-3 reposant sur l'algorithme keccak.

Spécificités
============

Le code keccak fourni est sous une forme lisible mais non optimisée:
http://keccak.noekeon.org/readable_code.html
Cette implémentation fonctionne en 64-bit little-endian.

Conditions de validité du benchmark
===================================

Le benchmark sponge s'exécute sur CPU, ou avec l'aide éventuelle de GPU compatible CUDA ou de coprocesseur compatible avec le jeu d'instruction x86. Le portage du code fourni vers ces composants de calculs est donc autorisé.

La durée maximale de ce benchmark est de 30 minutes, quelque soit la solution utilisée et quelque soit le niveau de performance.
La validité du checksum global sera vérifiée par l'administration au moment de la vérification d'aptitude.

Les optimisations dûes aux options de compilations sont autorisées.

Les optimisations autorisées sur ce benchmark sont:
- vectorisation / prefetching / cache blocking / loop unrolling / inlining,
- utilisation de fonctions intrinsèques et/ou asm volatile,
- aligner les données en mémoire,
- recourir à d'autres implémentations plus optimisées de keccak, fonctionnant sur les composants de calculs autorisés.

Mise en oeuvre
==============

 Description des arguments
 -------------------------
 ./sponge <pe> <nb_pe>
 où:
 <pe> désigne le rang du "processing element" courant, situé entre 0 et <nb_pe>-1.
 <nb_pe> désigne le nombre total de processus lancés.

 Exemple
 -------
 "./sponge 0 1024" exécute le "processing element" de rang 0 parmi 1024 processing elements.

 Vérification d'exécution
 ------------------------
 Le checksum global du benchmark s'obtient en appliquant un XOR sur le checksum de chaque "processing element".
 En mode test, le checksum global attendu vaut 948dd5b0109342d4:

 make test
 ./sponge_test 0 1
 948dd5b0109342d4
