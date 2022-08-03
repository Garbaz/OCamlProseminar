# Approaches to Asynchronous Execution across Languages

## Introduction

Fundamentally there are two kinds of operations in computing, CPU-bound operations and IO-bound operations, the former being operations where the limiting factor to performance is the speed with which calculations can be performed, whereas the latter are operations where performance is limited by the responses of systems external to the CPU. While for both kinds of operations, parallelization is a commonly taken approach to achieve improvements in performance, the way this parallelization is systematically structured and implemented is quite different for the two applications. In the following, I will specifically focus on the approaches provided by a selection of different languages to efficiently handle specifically IO-bound operations.

## Overview

The primary distinction of IO-bound tasks is that they generally consist of a small amount of computation, while having relatively long wait times. This means that each IO-bound task does not require much CPU time in total, but importantly, whenever an IO-bound task does have to do computation, it is usually important for it to get the necessary CPU time quickly, so that it can dispatch another message to and wait for a response from whatever external system it is interacting with.

So to handle a large number of such tasks simultaneously requires quick and efficient switching of tasks to fully utilize the processing resources available. However, ordinary threads as provided by most operating systems generally require too much time and resources to be created and deleted for them to be utilized directly. Therefore, most systems optimized for asynchronous execution of IO-bound tasks utilize a custom system that is abstracted over, or even entirely independent from, the parallelization systems provided by the underlying system architecture.

Another challenge in developing a system for asynchronous computation is the matter of a usable and safe abstract interface for programmers to interact with, due to it being such a fundamental change in how computation is organized inside a program. For this, two different approaches have developed, which are semantically similar, but conceptually and principally distinct.

One, generally aligned with the imperative programming paradigm, is to consider an asynchronous sequence of computation as one whole, which is then routinely interrupted and later resumed whenever it has to wait from some external asynchronous operation. This is usually implemented with bespoke features introduced into the language itself.

The other, generally aligned with the functional programming paradigm, is to instead consider an asynchronous sequence of computation to be made up of a chain of smaller asynchronous operations, resulting in a monadic structure where smaller asynchronous operations are composed into larger asynchronous operations.

These two approaches are dual to each other and in effect result in the same semantic model: Bursts of computation delineated by waiting for external responses.

## ...

## ...

# Summary