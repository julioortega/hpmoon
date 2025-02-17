function hpmoon(pop, gen)
% -------------------------------------------------------------------------
% ||||||||||||||||||||||||| GENERAL INFORMATION |||||||||||||||||||||||||||
% -------------------------------------------------------------------------
% FUNCTION HPMOON is the main file of a multi-objective optimization 
% procedure. This functions is based on evolutionary algorithm for finding
% the optimaL solution for multiple objective i.e. Pareto front for the 
% objectives. Initially enter only the population size and the stoping 
% criteria or the total number of generations after which the algorithm 
% will be automatically stopped. 
%
% You will be asked to enter the number of objective functions, and the 
% number of decision variables.
% Also you will have to define your own objective funciton by editing the
% evaluate_objective() function. A sample objective function is described
% in evaluate_objective.m. 
%
% - INPUT VARIABLES:
%   |_ 'pop': Population size (scalar).
%   |_ 'gen': Total number of generations (scalar).
% 
% - OUTPUT VARIABLES: none.
%
% -------------------------------------------------------------------------
% |||||||||||||||||||||| COPYRIGHT AND AUTHORSHIP |||||||||||||||||||||||||
% -------------------------------------------------------------------------
% Original algorithm NSGA-II was developed by researchers in Kanpur Genetic
% Algorithm Labarotary and kindly visit their website for more information
% http://www.iitk.ac.in/kangal/

%  Copyright (c) 2009, Aravind Seshadri. All rights reserved.
%
%  Redistribution and use in source and binary forms, with or without 
%  modification, are permitted provided that the following conditions are 
%  met:
%
%     * Redistributions of source code must retain the above copyright 
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright 
%       notice, this list of conditions and the following disclaimer in 
%       the documentation and/or other materials provided with the 
%       distribution.
%      
%  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
%  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
%  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
%  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
%  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
%  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
%  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
%  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
%  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
%  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
%  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
% - Adapted for multiobjective feature selection by:
%   |_ Dr. Prof. Andres Ortiz: 
%       * Entity:  Communications Engineering Department. University of 
%                  M�laga, Spain.
%       * Contact: aortiz@ic.uma.es
%   |_ Dr. Prof. Julio Ortega: 
%       * Entity:  Department of Computer Architecture and Computer
%                  Technology, University of Granada, Spain.
%       * Contact: jortega@ugr.es
%
% - Code restructuring and optimization:
%   |_ Dr. Alberto Olivares:
%       * Entity:   Department of Signal Theory, Telematics and
%                   Communications, University of Granada, Spain.
%       * Contact:  aolivares@ugr.es
%
% LAST MODIFICATION: 
%   |_ Date: 12/15/2014 (mm/dd/yy). 
%   |_ Location: Research Centre for Information and Communications 
%                Technologies of the University of Granada, Spain. 
%                (CITIC-UGR).
%
% -------------------------------------------------------------------------
% |||||||||||||||||||||| CODE STARTS RIGHT BELOW ||||||||||||||||||||||||||
% -------------------------------------------------------------------------

% 0) CHECK FOR THE NUMBER OF INPUT ARGUMENTS
% -------------------------------------------------------------------------
% Both input arguments are necessary to run this function.
if nargin < 2
    error(['NSGA-II: Please enter the population size and number of',...
        ' generations as input arguments.']);
end
% Both the input arguments need to be 'integers'.
if isnumeric(pop) == 0 || isnumeric(gen) == 0
    error('Both input arguments pop and gen should be integer datatype');
end
% Minimum population size has to be 20 individuals.
if pop < 20
    error('Minimum population for running this function is 20');
end
% Minimum number of generations must be 5.
if gen < 5
    error('Minimum number of generations is 5');
end
% Make sure pop and gen are integers.
pop = round(pop);
gen = round(gen);

% The objective function description contains information about the
% objective functions. 'M' is the dimension of the objective space, 'V' is 
% the dimension of the decision variable space.
% The individuals in the population are vectors of V binary components, 
% so min_range = 0 and max_range = 1.
% User has to define the objective functions using the decision variables. 
% Make sure to edit the function 'evaluate_objective_hpm' to suit your 
% needs.

% 1) SET AND INITIALIZE GENERAL PARAMETERS.
% -------------------------------------------------------------------------
% Prompt the user for the number of objective functions.
g = sprintf('Number of objectives: ');

% Get user's answer.
M = input(g); 

% Show an error if the number of objective functions is lower than 2.
if M < 2
    error(['This is a multi-objective optimization function hence',...
           'the minimum number of objectives is two']);
end

% Prompt the user for the number of decision variables (features).
g = sprintf('\nNumber of decision variables (features): ');

% Get user's answer (Number of componets of the individuals in the
% population).
V = input(g); 

% Prompt the user for the maximum number of features in the solution.
g = sprintf('\nMaximum number of features in solution (<=%i): ', V);

% Get user's anwer.
MAXfeat = input(g); 

min_range = 0; % Individuals with binary components (min_range=0).
max_range = 1; % Individuals with binary components (max_range=1).

% 2) INITIALIZATION OF THE POPULATION
% -------------------------------------------------------------------------
% Population is initialized with random values which are within the
% specified range. Each chromosome consists of the decision variables. Also
% the value of the objective functions, rank and crowding distance
% information are added to the chromosome vector but only the elements of 
% the vector which has the decision variables are operated upon to perform
% the genetic operations like crossover and mutation.

% Get initial time.
ti = clock; 

% Call the initialization function.
showChromosomes = 'yes';
chromosome = initialize_variables_hpm(pop, M, V, MAXfeat, showChromosomes);

% 3) SORT THE INITIALIZED POPULATION.
% -------------------------------------------------------------------------
% Sort the population using non-domination-sort. This returns two columns
% for each individual which are the rank and the crowding distance
% corresponding to their position in the front they belong. At this stage
% the rank and the crowding distance for each chromosome are added to the
% chromosome vector for ease of computation.

chromosome = non_domination_sort_mod(chromosome, M, V);

% 4) START THE EVOLUTION PROCESS.
% -------------------------------------------------------------------------
% The following steps are performed in each generation:
% * Select the parents which are fit for reproduction
% * Perfrom crossover and Mutation operator on the selected parents
% * Perform Selection from the parents and the offsprings
% * Replace the unfit individuals with the fit individuals to maintain a
%   constant population size.

for i = 1 : gen
    
    fprintf('GENERATION: %d \n', i);
    % 4.1) SELECTION OF THE PARENTS:
    % ---------------------------------------------------------------------
    % Parents are selected for reproduction to generate offspring. The
    % original NSGA-II uses a binary tournament selection based on the
    % crowded-comparision operator. 
    % The arguments are :
    % |_ 'pool': size of the mating pool. It is common to have this to be 
    %            half the population size.
    % |_ 'tour': tournament size. Original NSGA-II uses a binary tournament
    %            selection, but to see the effect of tournament size this 
    %            is kept arbitary, to be choosen by the user.
    
    pool = round(pop / 2);
    tour = 2;
    
    % 4.2) SELECTION PROCESS:
    % ---------------------------------------------------------------------
    % A binary tournament selection is employed in NSGA-II. In a binary
    % tournament selection process two individuals are selected at random
    % and their fitness is compared. The individual with better fitness is
    % selcted as a parent. Tournament selection is carried out until the
    % pool size is filled. Basically a pool size is the number of parents
    % to be selected. The input arguments to the function
    % 'tournament_selection' are chromosome, pool, tour. The function uses
    % only the information from last two elements in the chromosome vector.
    % The last element has the crowding distance information while the
    % penultimate element has the rank information. Selection is based on
    % rank and if individuals with same rank are encountered, crowding
    % distance is compared. A lower rank and higher crowding distance is
    % the selection criteria.
    
    fprintf('Tournament %d \n',i);
    parent_chromosome = tournament_selection(chromosome, pool, tour);

    % 4.3) PERFORM CROSSOVER AND MUTATION OPERATOR:
    % ---------------------------------------------------------------------
    % The original NSGA-II algorithm uses Simulated Binary Crossover (SBX) 
    % and Polynomial  mutation. Crossover probability 'pc = 0.9' and 
    % mutation probability is 'pm = 1/n', where 'n' is the number of 
    % decision variables.
    % Both real-coded GA and binary-coded GA are implemented in the 
    % original algorithm, while in this program only the real-coded GA is 
    % considered. The distribution indexes for crossover and mutation 
    % operators as 'mu = 20' and 'mum = 20' respectively.
    mu = 20;
    mum = 20;
   
    fprintf('Genetic Operator %d \n',i);
    offspring_chromosome = genetic_operator_hpm(parent_chromosome, M, ...
        V, mu, mum, min_range, max_range);

    % 4.4) INTERMEDIATE POPULATION:
    % ---------------------------------------------------------------------
    % Intermediate population is the combined population of parents and
    % offsprings of the current generation. The population size is two
    % times the initial population.
    
    % fprintf('Size %d \n',i);
    [main_pop, temp] = size(chromosome);
    [offspring_pop, temp] = size(offspring_chromosome);
    
    % temp is a dummy variable.
    clear temp
    
    % 'intermediate_chromosome' is a concatenation of current population 
    % and the offspring population.
    
    fprintf('Intermediate %d \n',i);
    intermediate_chromosome(1: main_pop, :) = chromosome;
    intermediate_chromosome(main_pop + 1 : main_pop + offspring_pop, ...
        1 : M + V) = offspring_chromosome;
    
    % 4.5) NON-DOMINANT-SORT OF INTERMEDIATE POPULATION:
    % ---------------------------------------------------------------------
    % The intermediate population is sorted again based on non-domination
    % sort before the replacement operator is performed on the intermediate
    % population.
    
    fprintf('Non domination sort %d \n',i);
    intermediate_chromosome = ...
        non_domination_sort_mod(intermediate_chromosome, M, V);
    
    % 4.6) PERFORM SELECTION:
    % ---------------------------------------------------------------------
    % Once the intermediate population is sorted only the best solution is
    % selected based on it rank and crowding distance. Each front is filled
    % in ascending order until the addition of population size is reached. 
    % The last front is included in the population based on the individuals
    % with least crowding distance.
    
    % fprintf('Replace chromosome %d \n',i);
    chromosome = replace_chromosome(intermediate_chromosome, M, V, pop);
    if ~mod(i,100)
        clc
        fprintf('%d generations completed \n',i);
    end
end
% Get end time;
tf = etime(clock, ti); 

fprintf('Time: %d seconds\n', tf);

% 5) PROCESS AND SAVE RESULTS.
% -------------------------------------------------------------------------
% Save the result in ASCII text format.
save solution.txt chromosome -ASCII;
save solution.mat chromosome;

result = chromosome(:, (V + 1) : size(chromosome, 2));
save pareto.txt result -ASCII;

for i = 1 : size(chromosome,1)
    xyz = find(chromosome(i, 1 : V));
    save features.txt xyz -append -ASCII;
end

% 6) VISUALIZE RESULTS.
% -------------------------------------------------------------------------
% The following is used to visualize the result if objective space
% dimension is visualizable.
if M == 2
    plot(chromosome(:, V + 1), chromosome(:, V + 2), '*');
elseif M == 3
    plot3(chromosome(:, V + 1), chromosome(:, V + 2),...
        chromosome(:, V + 3),'*');
end
    
% -------------------------------------------------------------------------
% ||||||||||||||||||||||| END OF HPMOON FUNCTION ||||||||||||||||||||||||||
% -------------------------------------------------------------------------