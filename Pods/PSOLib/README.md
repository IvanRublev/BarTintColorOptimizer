[![CI Status](http://img.shields.io/travis/IvanRublev/PSOLib.svg?style=flat)](https://travis-ci.org/IvanRublev/VRFoundationToolkit)
[![Version](https://img.shields.io/cocoapods/v/PSOLib.svg?style=flat)](http://cocoapods.org/pods/PSOLib)
[![License](https://img.shields.io/cocoapods/l/PSOLib.svg?style=flat)](http://cocoapods.org/pods/PSOLib)
[![Platform](https://img.shields.io/cocoapods/p/PSOLib.svg?style=flat)](http://cocoapods.org/pods/PSOLib)

Purpose
-------

Particle Swarm Optimization library for iOS and OSX is intended to optimize non-linear mathematical problems where the solution could be represented as a point in multidimensional space.

The main idea of the PSO algorithm is to use a population of particles that flies through the multidimensional search space estimating each position with a common fitness function. Particles memorizes the best position visited, exchange that information with their neighbors, changes their speeds randomly respecting self's best position and best position of their neighborhood. Search stops when any particle finds the exact solution - the best position that has the closest fitness value to the optimum set. If exact solution couldn't be found then algorithm stops when max iterations count is reached. In that case the last best position found among particles is returned. 

Original algorithm was developed by Dr. Eberhart and Dr. Kennedy in 1995 ([original papers](https://scholar.google.com/scholar?as_q=&as_occt=any&as_sauthors=Kennedy+J%2C+Eberhart+RC&as_ylo=1995&as_yhi=1995)).
Good introduction to PSO could be found in [Artificial Life by example!](http://web.ist.utl.pt/gdgp/VA/pso.htm) article and on the [http://www.swarmintelligence.org](http://www.swarmintelligence.org/tutorials.php) website.

The PSOLib implements the Standard 2011 algorithm that was developed by PSO community. The code is ported from [MATLAB version](http://www.particleswarm.info/SPSO2011_matlab.zip) made by Dr. Mahamed G.H. Omran and Maurice Clerc. To get the details on the development of the standard see the [Standard Particle Swarm Optimisation From 2006 to 2011](http://clerc.maurice.free.fr/pso/SPSO_descriptions.pdf) paper.


Performance
-----------
The library interface is written in Objective-C. Pure C arrays are used internally to store data. The Accelerate framework functions are used to perform velocities and positions calculations. To get the best performance it's recommended to use Accelerate framework when calculating user fitness function as also.

Search the minimum of 3 dimensional sphere function takes about ~206ms in ~180 iterations on iPhone 5 (Model A1428). The Objective-C code used for benchmark is shown below in Usage section.


Installation
------------

Use Cocoapods. Add the following line to your Podfile:

```
pod "PSOLib", "~> 1.0.0"
```

And then run following command in projects directory:

```console
pod install
```

Then import the PSOLib framework in your source code:

```objc
@import PSOLib;
```

If you want to use library on iOS 7.x or don't use pods as frameworks (haven't define `use_frameworks!` flag in your Podfile) then import the umbrella header directly in your source code:

```objc
#import <PSOLib/PSOLib.h>
```

If you don't use Cocoapods you can clone the repository and add library files from `Pod` directory to your project.


Usage
-----

You define the problem (e.g. search space, fitness function, optimum value) via the `PSOStandardOptimizer2011` class instance. Then obtain `NSOperation` object from the optimizer instance. Start the obtained operation. When it finishes the `finish` block is fired where you can obtain the solution.

####Objective-C

Here is an example of finding position where sphere function is minimal (that's x(i)=0):

```objc
@import PSOLib;
// ...

PSOSearchSpace *searchSpace = [PSOSearchSpace 
								searchSpaceWithBoundsMin:@[@-95, @-80, @-100]
								max:@[@95, @80, @100]]; // 1
	
PSOStandardOptimizer2011 *optimizer =
[PSOStandardOptimizer2011
	optimizerForSearchSpace:searchSpace
	optimum:0.                                   // 2
	fitness:^double(double *x, int dimensions) { // 3
		// sum(x.^2)
		double squares[dimensions];
		vDSP_vsqD(x, 1, squares, 1, dimensions);
		double sum = 0;
		vDSP_sveD(squares, 1, &sum, dimensions);
		return sum;
        }
	before:nil
	iteration:nil
	finished:^(PSOStandardOptimizer2011 *optimizer) { // 4
		NSLog(@"Best fitness %f best position %@ iteration %lu",
			  optimizer.bestFitness,
			  optimizer.bestPosition, 
			  (unsigned long)optimizer.iteration);
	}];
		
[optimizer.operation start]; // 5
```

1. Problem's search space. Here we define three dimensional search space bounded to appropriate min and max values.
2. Set the target optimum fitness value.
3. Fitness function block. It will be called to evaluate the fitness value for each position of each particle. We use Accelerate framework functions to calculate the sum of coordinates squares.
4. Finished block. Will be called once when the solution search operation finishes.
5. Start the solution search operation.


You can choose to use the delegate object for fitness function calculation. The delegate object must conform to `PSOfitnessCalculating` protocol.

```objc
@import PSOLib;
// ...

SphereFunction* sphereFunctionCalculator = [SphereFunction new]; // 1
        
PSOSearchSpace *searchSpace = [PSOSearchSpace 
								searchSpaceWithBoundsMin:@[@-95, @-80, @-100]
								max:@[@95, @80, @100]];
       
PSOStandardOptimizer2011 *optimizer =
[PSOStandardOptimizer2011
	optimizerForSearchSpace:searchSpace
	optimum:0.
	fitnessCalculator:sphereFunctionCalculator   // 2
	before:nil
	iteration:nil
	finished:^(PSOStandardOptimizer2011 *optimizer) {
		NSLog(@"Best fitness %f best position %@ iteration %lu",
			  optimizer.bestFitness,
			  optimizer.bestPosition, 
			  (unsigned long)optimizer.iteration);
	}];
        
[optimizer.operation start];

// ... in SphereFunction class implementation
	
- (void)optimizer:(PSOStandardOptimizer2011 *)optimizer 
 getFitnessValues:(out double *)fitnessValues
forPositionsBunch:(double **)positions
			 size:(NSUInteger)bunchSize
	   dimensions:(int)dimensions { // 3
	for (NSUInteger positionIdx=0; positionIdx<bunchSize; positionIdx++) { // sum(x.^2)
		double squares[dimensions];
		vDSP_vsqD(positions[positionIdx], 1, squares, 1, dimensions);
		double sum = 0;
		vDSP_sveD(squares, 1, &sum, dimensions);
		fitnessValues[positionIdx] = sum;
	}
}
```

1. Making new calculator object that conforms to `PSOfitnessCalculating` protocol.
2. Defining problem and set the fitness function calculator object.
3. Evaluate fitness function for all positions passed in.

####Swift

If you install the library as a framework it's automatically available to Swift apps. The first example shown above could be rewritten in Swift as following:

```swift
import PSOLib

let searchSpace = PSOSearchSpace(boundsMin: [-95, -80, -100], max: [95, 80, 100])

let optimizer = PSOStandardOptimizer2011 .optimizerForSearchSpace(
	searchSpace,
	optimum: 0,
	fitness: { (positions: UnsafeMutablePointer<Double>, dimensions: Int32) -> Double in
		var squares = [Double](count: Int(dimensions), repeatedValue: 0.0)
		vDSP_vsqD(positions, 1, &squares, 1, vDSP_Length(dimensions))
		var sum: Double = 0
		vDSP_sveD(squares, 1, &sum, vDSP_Length(dimensions))
		return sum
	},
	before: nil,
	iteration: nil,
	finished: { (optimizer: PSOStandardOptimizer2011!) -> Void in
		NSLog("Best fitness %f best position %@ iteration %lu", 
			  optimizer.bestFitness, 
			  optimizer.bestPosition,
			  optimizer.iteration)
	})

optimizer.operation.start()
```

####Common notes

The optimizer object of `PSOStandardOptimizer2011` class works as operations instance factory. Each time you get the operation property of the optimizer object the optimizer object is copied internally and a new instance of the operation which will use that copy of the optimizer is returned. That's why you must set all necessary input properties values before getting the operation. You can use tag property to identify optimizer objects passed in completion blocks.

Other useful properties of the optimizer class are:

* fitnessError - the allowed error of optimum value. By default is set to DBL_EPSILON. Solution is considered to be found when the fitness value is close to optimum value within the set error.
* maxIterations - Maximum count of iterations at which the algorithm must stop. By default is set to 100,000.

For further details see the sources and the Example project. To open the example project run following command:

```console
pod try PSOLib
```


Release notes
-------------

1.0.0 - Initial release.


Library author
--------------

Ivan Rublev, ivan@ivanrublev.me


License
-------

PSOLib is available under the MIT license. See the LICENSE file for more info.
