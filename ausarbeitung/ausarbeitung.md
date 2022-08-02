# Approaches to Asynchronous Execution across Languages

## Introduction

Fundamentally there are two kinds of operations in computing, CPU-bound operations and IO-bound operations, the former being operations where the limiting factor to performance is the speed with which calculations can be performed, whereas the latter are operations where performance is limited by the responses of external systems like file systems or network devices. While for both kinds of operations, parallelization is a commonly taken approach to achieve improvements in performance, the way this parallelization systematically structured and implemented is quite different. And so in the following, I will specifically focus on the approaches provided by a selection of different languages to asynchronously handle IO-bound operations.

## Overview

The primary distinction of IO-bound tasks is that they generally do not consist of much effective computation time, while having relatively long wait times. While this means that each IO-bound tasks effectively does not require much computation time in total, handling a large number of such tasks proves challenging, since it requires quick and efficient switching of tasks to fully utilize the processing resources available. However, threads as provided by most operating systems require too much time and resources to create and delete a thread for them to be utilized directly. Therefore, most systems optimized for asynchronous execution of IO-bound tasks utilize a custom system that is abstracted over, or even entirely independent from, the parallelization systems provided by the underlying system architecture.

Another challenge in developing a system for asynchronous computation is the matter of a usable and safe abstract programming interface, due to it being such a fundamental change in how computation is organized inside a program. For this, two different approaches have developed, which are semantically similar, but conceptually and principally distinct.

One, chosen primarily by imperative programming languages, is to consider an asynchronous sequence of computation as one whole, which is routinely interrupted and resumed each time it has to wait from some external asynchronous operation. This is usually implemented with bespoke keywords introduced into the language.

The other, chosen primarily by functional programming languages, is to instead consider an asynchronous sequence of computation to be made up of a chain of smaller asynchronous operations. This is usually implemented via a monadic structure.

These two approaches are in a way dual to each other and in effect result in the same execution model, where each burst of execution is handled as a distinct task, with the waiting for external responses as the lines separating each.

## ...

## ...

# Summary